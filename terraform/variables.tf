variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "polygon_rpc_url" {
  description = "Polygon RPC URL"
  type        = string
  default     = "https://polygon-rpc.com/"
} 