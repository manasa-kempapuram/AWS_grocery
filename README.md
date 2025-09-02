**🛒 GroceryMate – Cloud-Based Grocery App on AWS**

**📌 Description**

GroceryMate is a grocery inventory and shopping list manager built using Flask and deployed on Amazon Web Services. It uses Docker for containerization and Terraform for infrastructure provisioning. The infrastructure includes a highly available architecture with VPC, public/private subnets, an Application Load Balancer (ALB), and an Auto Scaling Group (ASG). The setup can be manually operated via the AWS Console or automated with Terraform scripts.

**🚀 Features**

- Python Flask web application running on EC2 (Amazon Linux)
- PostgreSQL database on Amazon RDS (Private subnet)
- Static asset storage using Amazon S3
- Infrastructure as Code using Terraform
- Dockerized deployment for portability
- Application Load Balancer and Auto Scaling Group
- Segregated public and private subnets in a custom VPC

**🧰 Tech Stack**

| **Component** | **Technology** |
| --- | --- |
| Frontend/App | Flask (Python) |
| Containerization | Docker |
| Database | Amazon RDS (PostgreSQL) |
| Object Storage | Amazon S3 |
| Deployment | EC2 (Amazon Linux) |
| Load Balancing | Application Load Balancer (ALB) |
| Scaling | Auto Scaling Group (ASG) |
| Networking | VPC, Public/Private Subnets |
| IaC Tool | Terraform |

**🏗️ Architecture Diagram**

<img width="464" height="312" alt="Diagram" src="https://github.com/user-attachments/assets/8d35a1ba-6e8a-46a1-8705-52e0eee11c6b" />

**Key Elements:**

- **VPC** with 2 Public and 2 Private Subnets across multiple Availability Zones
- **EC2 instances** inside an **Auto Scaling Group**, behind an **Application Load Balancer**
- **Amazon RDS (PostgreSQL)** instance in Private Subnet
- **Amazon S3** bucket for static assets
- **Security Groups** and **IAM roles** for access control

**🐳 Dockerized Deployment**

**🔧 How to Run with Docker**

docker build -t grocerymate-app .

docker run -d -p 5000:5000 grocerymate-app

The app will be accessible at <http://localhost:5000>

📌 Ensure the appropriate ALB listener and target group are configured to forward requests to EC2 on the correct port.

**📦 Terraform Infrastructure**

**🌱 Prerequisites**

- Terraform installed
- AWS CLI configured
- terraform.tfvars file containing:

region = "us-east-1"

db_name = "grocerydb"

db_user = "admin"

db_pass = "yourpassword"

instance_type = "t3.micro"

**⚙️ Terraform Commands**

terraform init

terraform plan

terraform apply

**💡 Provisions**

- Custom VPC with Public and Private Subnets
- EC2 instances inside Auto Scaling Group
- Application Load Balancer
- RDS PostgreSQL instance in Private Subnet
- S3 bucket
- IAM roles
- Security groups

**🔧 Manual Setup via AWS Console**

**1\. VPC and Subnets**

- Create a custom VPC
- Add 2 Public and 2 Private Subnets
- Associate route tables appropriately

**2\. Launch EC2 Instances via Auto Scaling Group**

- OS: Amazon Linux
- Launch configuration with Flask app AMI and startup script
- Target group for ALB, attach to ASG

**3\. Set Up RDS (Private)**

- Engine: PostgreSQL
- Deploy in Private Subnet
- Make sure the RDS security group allows traffic from EC2 instances on port 5432

**4\. Configure ALB**

- Create an ALB in the Public Subnet
- Listener: HTTP (80) → Target Group (EC2 on 5000)

**5\. Configure S3**

- Create an S3 bucket for storing images/assets
- Set appropriate bucket policies for public or signed URL access

**🔐 Security Group Configuration**

| **Source** | **Destination** | **Port** | **Purpose** |
| --- | --- | --- | --- |
| Your IP | EC2 | 22  | SSH Access |
| ALB | EC2 | 5000 | Flask Web Access |
| EC2 Security Group | RDS | 5432 | PostgreSQL DB Access |

**📂 Folder Structure**

├── app.py

├── Dockerfile

├── templates/

│ └── index.html

├── static/

│ └── style.css

├── terraform/

│ ├── main.tf

│ ├── variables.tf

│ └── terraform.tfvars

├── requirements.txt

**📚 Learning Outcomes**

- Designing a scalable AWS architecture with VPCs, ALB, and ASG
- Manual and automated provisioning of AWS infrastructure
- Docker containerization of Flask applications
- Secure networking using Security Groups, private subnets, and IAM roles
