# Polygon Blockchain Client

polygon-client/
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── blockchain.py
│   └── config.py
├── tests/
│   ├── __init__.py
│   ├── test_blockchain.py
│   └── test_api.py
├── Dockerfile
├── requirements.txt
├── README.md
└── terraform/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf

A simple blockchain client for the Polygon network that exposes an API for interacting with the blockchain.

## Features

- Get the current block number
- Get block details by block number
- FastAPI-powered REST API with automatic docs
- Containerized application
- AWS ECS Fargate deployment with Terraform

## Prerequisites

- Python 3.9+
- Docker
- Terraform 1.0+ (for deployment)
- AWS account (for deployment)

## Local Development

1. Create a virtual environment and activate it:

```bash
python -m venv venv
source venv/bin/activate # On Windows: venv\Scripts\activate
```

2. Install dependencies:

```bash
pip install -r requirements.txt
```

3. Run the application:

```bash
python -m app.main
```

4. Access the API documentation at http://localhost:8000/docs

## Testing

Run tests with pytest:

```bash
pytest
```

## Building the Docker Image

```bash
docker build -t polygon-client .
```

Run the containerized application:

```bash
docker run -p 8000:8000 polygon-client
```

## Deployment with Terraform

1. Initialize Terraform:

```bash 
cd terraform
terraform init
```

2. Plan the deployment:

```bash
terraform plan -out=polygon-client.tfplan
```

3. Apply the plan:

```bash
terraform apply polygon-client.tfplan
```

4. Get the load balancer DNS name:

```bash
terraform output load_balancer_dns
```

## API Endpoints

- `GET /health` - Health check endpoint
- `GET /block/number` - Get the current block number
- `POST /block/by-number` - Get block by number with JSON body:
  ```json
  {
    "block_number": "0x134e82a",
    "include_transactions": true
  }
  ```

## Production Readiness Considerations

To make this application production-ready, consider implementing the following:

1. **Authentication and Authorization**:
   - Add API keys or OAuth2 authentication
   - Implement role-based access control

2. **Rate Limiting**:
   - Implement rate limiting to prevent abuse
   - Add request quotas per client

3. **Monitoring and Alerting**:
   - Add metrics collection (Prometheus/CloudWatch)
   - Set up alerting for critical failures
   - Implement detailed logging and log aggregation

4. **High Availability**:
   - Use multiple RPC endpoints with fallback mechanisms
   - Implement circuit breakers for RPC calls
   - Set up caching for frequently accessed data

5. **Security Enhancements**:
   - Add HTTPS with proper certificate management
   - Implement Web Application Firewall (WAF)
   - Regular vulnerability scanning and dependency updates

6. **CI/CD Pipeline**:
   - Automated testing and deployment
   - Infrastructure as Code validation
   - Container image scanning

7. **Performance Optimization**:
   - Response caching
   - Connection pooling for RPC requests
   - Response compression

8. **Error Handling and Recovery**:
   - Graceful error handling with useful client messages
   - Automatic retry policies for transient failures

9. **Backup and Disaster Recovery**:
   - Regular backups of any stateful data
   - Disaster recovery plan and testing

10. **Documentation**:
    - Comprehensive API documentation
    - Runbooks for common operational tasks
    - System architecture diagrams

By addressing these areas, the application would be much more suitable for production use in enterprise environments.
