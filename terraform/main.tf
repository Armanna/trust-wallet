wprovider "aws" {
  region = var.aws_region
}

# VPC and networking
resource "aws_vpc" "polygon_client_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "polygon-client-vpc"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.polygon_client_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "polygon-client-public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.polygon_client_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "polygon-client-public-subnet-2"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.polygon_client_vpc.id

  tags = {
    Name = "polygon-client-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.polygon_client_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "polygon-client-public-rt"
  }
}

resource "aws_route_table_association" "public_subnet_1_rta" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_subnet_2_rta" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group
resource "aws_security_group" "polygon_client_sg" {
  name        = "polygon-client-sg"
  description = "Security group for Polygon client"
  vpc_id      = aws_vpc.polygon_client_vpc.id

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "polygon-client-sg"
  }
}

# ECR Repository
resource "aws_ecr_repository" "polygon_client_repo" {
  name                 = "polygon-client"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "polygon_client_cluster" {
  name = "polygon-client-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "polygon-client-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task Definition
resource "aws_ecs_task_definition" "polygon_client_task" {
  family                   = "polygon-client"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "polygon-client"
      image     = "${aws_ecr_repository.polygon_client_repo.repository_url}:latest"
      essential = true
      
      environment = [
        {
          name  = "POLYGON_RPC_URL"
          value = var.polygon_rpc_url
        },
        {
          name  = "API_PORT"
          value = "8000"
        }
      ]
      
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/polygon-client"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "polygon_client_logs" {
  name              = "/ecs/polygon-client"
  retention_in_days = 30
}

# ECS Service
resource "aws_ecs_service" "polygon_client_service" {
  name            = "polygon-client-service"
  cluster         = aws_ecs_cluster.polygon_client_cluster.id
  task_definition = aws_ecs_task_definition.polygon_client_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
    security_groups  = [aws_security_group.polygon_client_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.polygon_client_tg.arn
    container_name   = "polygon-client"
    container_port   = 8000
  }

  depends_on = [aws_lb_listener.http]
}

# Load Balancer
resource "aws_lb" "polygon_client_lb" {
  name               = "polygon-client-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.polygon_client_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

resource "aws_lb_target_group" "polygon_client_tg" {
  name        = "polygon-client-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.polygon_client_vpc.id
  target_type = "ip"

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.polygon_client_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.polygon_client_tg.arn
  }
} 