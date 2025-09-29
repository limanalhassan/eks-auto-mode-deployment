# EKS Auto-Mode Deployment

This project demonstrates an automated deployment infrastructure for running applications on Amazon EKS (Elastic Kubernetes Service) using GitOps principles. It includes a sample Go application and complete infrastructure as code using Terraform.

## Project Structure

```
eks-auto-mode-deployment/
├── application/              # Application deployment manifests
│   ├── dev/                 # Development environment
│   ├── prod/                # Production environment
│   └── staging/             # Staging environment
├── infrastructure/          # Terraform infrastructure code
│   ├── backend/            # Terraform state management
│   ├── helm-valuesFiles/   # Helm chart values
│   └── *.tf                # Terraform configuration files
├── Dockerfile              # Container image definition
├── main.go                 # Sample Go application
└── README.md              # This file
```

## Features

- **Multi-Environment Support**: Separate configurations for dev, staging, and production
- **GitOps with ArgoCD**: Automated deployment and synchronization
- **Infrastructure as Code**: Complete AWS infrastructure managed with Terraform
- **Load Balancing**: AWS Application Load Balancer (ALB) integration
- **SSL/TLS**: Automatic certificate management with ACM
- **DNS Management**: Cloudflare DNS integration
- **Monitoring**: Metrics server integration

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.3.2
- kubectl
- Docker
- Go >= 1.16 (for local development)

## Infrastructure Components

### AWS Resources
- EKS Cluster
- VPC with public/private subnets
- Application Load Balancer (ALB)
- ACM Certificates
- S3 (for Terraform state)
- DynamoDB (for state locking)

### Kubernetes Components
- ArgoCD for GitOps
- ALB Ingress Controller
- Metrics Server
- Application namespaces and resources

## Getting Started

### Local Development

1. Build and run the Go application locally:
   ```bash
   go build main.go
   ./main
   ```
   Or using Go run:
   ```bash
   go run main.go
   ```

2. Build and test with Docker:
   ```bash
   docker build -t hello-world .
   docker run -e "ENV=production" --rm -p 8080:8080 hello-world
   ```

### Infrastructure Deployment

1. Initialize Terraform:
   ```bash
   cd infrastructure
   terraform init
   ```

2. Review the infrastructure plan:
   ```bash
   terraform plan
   ```

3. Apply the infrastructure:
   ```bash
   terraform apply
   ```

### Application Deployment

The application is automatically deployed through ArgoCD once the infrastructure is up. ArgoCD will:
1. Watch the Git repository for changes
2. Automatically sync changes to the appropriate environment
3. Maintain the desired state in the cluster

## Environment-Specific Configurations

- **Dev**: `/application/dev/dev.yaml`
- **Staging**: `/application/staging/staging.yaml`
- **Production**: `/application/prod/prod.yaml`

Each environment can be configured with:
- Resource limits and requests
- Replica counts
- Environment variables
- Ingress configurations

## Terraform State Management

The project uses remote state storage with:
- S3 bucket for state files
- DynamoDB for state locking
- Configured in `/infrastructure/backend/backend.tf`

## Monitoring and Access

- Application metrics: Available through metrics-server
- Load balancer: Accessible through ALB DNS
- ArgoCD UI: Available through configured ingress
- Application endpoints: Accessible through configured DNS

## Security Features

- SSL/TLS termination at ALB
- Private VPC subnets for EKS nodes
- IAM roles and policies for least privilege
- Network policies for pod communication
- Secrets management through AWS Secrets Manager

## Troubleshooting

1. Check ArgoCD application status:
   ```bash
   kubectl get applications -n argocd
   ```

2. View application logs:
   ```bash
   kubectl logs -n liman-app -l app=hello-world
   ```

3. Check ALB health:
   ```bash
   kubectl get ingress -n liman-app
   ```
