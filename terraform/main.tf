terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "~> 2.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source = "hashicorp/local"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

resource "random_id" "env_display_id" {
    byte_length = 4
}

# --- 1. Confluent Cloud Environment & Cluster (Basic) ---

resource "confluent_environment" "staging" {
  display_name = "Workshop-${random_id.env_display_id.hex}"
}

resource "confluent_kafka_cluster" "basic" {
  display_name = "workshop-${random_id.env_display_id.hex}"
  availability = "SINGLE_ZONE"
  cloud        = "AWS"
  region       = var.aws_region
  basic {}

  environment {
    id = confluent_environment.staging.id
  }
}

# --- 2. Retrieve Confluent Egress IPs (The Secure Method) ---

data "confluent_ip_addresses" "main" {
  filter {
    clouds        = ["AWS"]
    regions       = [var.aws_region]
    address_types = ["EGRESS"]
  }
}

# --- 3. Cluster API Key & Role Binding ---

resource "confluent_service_account" "app_manager" {
  display_name = "app-manager-${random_id.env_display_id.hex}"
  description  = "Service account for the application"
}

resource "confluent_role_binding" "app_manager_kafka_cluster_admin" {
  principal   = "User:${confluent_service_account.app_manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.basic.rbac_crn
}

resource "confluent_api_key" "app_manager_kafka_api_key" {
  display_name = "app-manager-kafka-api-key-${random_id.env_display_id.hex}"
  description  = "Kafka API Key owned by app-manager-${random_id.env_display_id.hex}"
  owner {
    id          = confluent_service_account.app_manager.id
    api_version = confluent_service_account.app_manager.api_version
    kind        = confluent_service_account.app_manager.kind
  }
  managed_resource {
    id          = confluent_kafka_cluster.basic.id
    api_version = confluent_kafka_cluster.basic.api_version
    kind        = confluent_kafka_cluster.basic.kind
    environment {
      id = confluent_environment.staging.id
    }
  }
  depends_on = [confluent_role_binding.app_manager_kafka_cluster_admin]
}

# --- Flink Compute pool ---

resource "confluent_flink_compute_pool" "flinkpool-main" {
  display_name     = "workshop_${random_id.env_display_id.hex}"
  cloud            = "AWS"
  region           = var.aws_region
  max_cfu          = 10
  environment {
    id = confluent_environment.staging.id
  }
}

# --- 4. AWS Networking ---

data "aws_vpc" "default" {
  default = true
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "main" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = cidrsubnet(data.aws_vpc.default.cidr_block, 8, 100)
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = { Name = "terraform-confluent-subnet-1" }
}

resource "aws_subnet" "secondary" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = cidrsubnet(data.aws_vpc.default.cidr_block, 8, 110)
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = { Name = "terraform-confluent-subnet-2" }
}

resource "aws_db_subnet_group" "aurora" {
  name       = "aurora_subnet_group"
  subnet_ids = [aws_subnet.main.id, aws_subnet.secondary.id]
}

# --- 5. Aurora PostgreSQL & Security Group ---

resource "aws_rds_cluster_parameter_group" "cdc_params" {
  name        = "aurora-postgres-cdc-params"
  family      = "aurora-postgresql16" # Must match the engine version family
  description = "Enable logical replication for CDC"

  # This is the critical setting for CDC
  parameter {
    name         = "rds.logical_replication"
    value        = "1"
    apply_method = "pending-reboot" # Requires reboot, happens on creation
  }

  # Optional: Helpful for preventing timeouts during large initial snapshots
  parameter {
    name  = "wal_sender_timeout"
    value = "0" 
  }
}

resource "aws_security_group" "aurora_sg" {
  name        = "aurora_sg"
  description = "Aurora SG - Confluent Egress IPs Only"
  vpc_id      = data.aws_vpc.default.id

  # DYNAMIC INGRESS RULE:
  # Allows only the specific IPs retrieved from Confluent data source
  ingress {
    description = "Confluent Cloud Shared Egress IPs"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [for ip in data.confluent_ip_addresses.main.ip_addresses : ip.ip_prefix]
  }

  ingress {
    description = "VPC cidr IPs"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_rds_cluster" "postgresql" {
  cluster_identifier      = "aurora-cluster-demo"
  engine                  = "aurora-postgresql"
  engine_mode             = "provisioned"
  engine_version          = var.db_version
  database_name           = var.db_name
  master_username         = var.db_username
  master_password         = var.db_password
  skip_final_snapshot     = true
  db_subnet_group_name    = aws_db_subnet_group.aurora.name
  vpc_security_group_ids  = [aws_security_group.aurora_sg.id]

  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.cdc_params.name
  
  # Ensure changes apply immediately if updating an existing cluster
  apply_immediately = true
  
  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0.5
  }
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  identifier           = "aurora-node-1"
  cluster_identifier   = aws_rds_cluster.postgresql.id
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.postgresql.engine
  engine_version       = aws_rds_cluster.postgresql.engine_version
  publicly_accessible  = true
}

# --- 6. EC2 Client ---

# Generate SSH Key
resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = "confluent-demo-key"
  public_key = tls_private_key.pk.public_key_openssh
}

resource "local_file" "ssh_key" {
  filename        = "${path.module}/workshop-key.pem"
  content         = tls_private_key.pk.private_key_pem
  file_permission = "0400"
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2_bastion_sg"
  description = "Allow SSH only"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "client" {
  ami                         = var.aws_ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.main.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  key_name                    = aws_key_pair.kp.key_name
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y java-17-amazon-corretto-devel postgresql16
    rpm --import https://packages.confluent.io/rpm/8.1/archive.key
    printf "[Confluent.dist]\nname=Confluent repository (dist)\nbaseurl=https://packages.confluent.io/rpm/8.1\ngpgcheck=1\ngpgkey=https://packages.confluent.io/rpm/8.1/archive.key\nenabled=1\n\n[Confluent]\nname=Confluent repository\nbaseurl=https://packages.confluent.io/rpm/8.1\ngpgcheck=1\ngpgkey=https://packages.confluent.io/rpm/8.1/archive.key\nenabled=1\n" > /etc/yum.repos.d/confluent.repo
    dnf install -y confluent-cli python3-pip python3-devel gcc openssl-devel
    pip3 install confluent-kafka psycopg2-binary faker
    pip3 install --upgrade attrs certifi httpx cachetools authlib fastavro
  EOF

  tags = { Name = "Confluent-Client-Producer" }
}

resource "aws_instance" "client2" {
  ami                         = var.aws_ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.main.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  key_name                    = aws_key_pair.kp.key_name
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y java-17-amazon-corretto-devel postgresql16
    rpm --import https://packages.confluent.io/rpm/8.1/archive.key
    printf "[Confluent.dist]\nname=Confluent repository (dist)\nbaseurl=https://packages.confluent.io/rpm/8.1\ngpgcheck=1\ngpgkey=https://packages.confluent.io/rpm/8.1/archive.key\nenabled=1\n\n[Confluent]\nname=Confluent repository\nbaseurl=https://packages.confluent.io/rpm/8.1\ngpgcheck=1\ngpgkey=https://packages.confluent.io/rpm/8.1/archive.key\nenabled=1\n" > /etc/yum.repos.d/confluent.repo
    dnf install -y confluent-cli python3-pip python3-devel gcc openssl-devel
    pip3 install confluent-kafka psycopg2-binary faker
    pip3 install --upgrade attrs certifi httpx cachetools authlib fastavro
  EOF

  tags = { Name = "Confluent-Client-Consumer" }
}

# --- Outputs ---

output "default_vpc_cidr" {
  description = "The CIDR block of the default VPC"
  value       = data.aws_vpc.default.cidr_block
}

output "confluent_cluster_bootstrap" {
  value = confluent_kafka_cluster.basic.bootstrap_endpoint
}

output "confluent_api_key" {
  value     = confluent_api_key.app_manager_kafka_api_key.id
  sensitive = true
}

output "confluent_api_secret" {
  value     = confluent_api_key.app_manager_kafka_api_key.secret
  sensitive = true
}

output "confluent_egress_ips" {
  value = [for ip in data.confluent_ip_addresses.main.ip_addresses : ip.ip_prefix]
}

output "aurora_endpoint" {
  value = aws_rds_cluster.postgresql.endpoint
}

output "ec2_public_ip" {
  value = aws_instance.client.public_ip
}

output "ssh_private_key_command" {
  value = "ssh -i confluent-demo-key.pem ec2-user@${aws_instance.client.public_ip}"
}

resource "local_file" "output_file" {
  filename = "./workshop.json"
  content  = <<-EOT
  # Confluent Cloud

  "confluent_environment": ${confluent_environment.staging.display_name}
  "confluent_cluster_bootstrap": ${confluent_kafka_cluster.basic.bootstrap_endpoint}
  "confluent_api_key": ${confluent_api_key.app_manager_kafka_api_key.id}
  "confluent_api_secret": ${confluent_api_key.app_manager_kafka_api_key.secret}

  # AWS
  
  # EC2
  "producer_public_ip": ${aws_instance.client.public_ip}
  "consumer_public_ip": ${aws_instance.client2.public_ip}
  "ssh_private_key_command (producer)": "ssh -i confluent-demo-key.pem ec2-user@${aws_instance.client.public_ip}"
  "ssh_private_key_command (consumer)": "ssh -i confluent-demo-key.pem ec2-user@${aws_instance.client2.public_ip}"

  # Postgres
  "aurora_endpoint": ${aws_rds_cluster.postgresql.endpoint}
  "psql_command": "psql -h ${aws_rds_cluster.postgresql.endpoint} -p 5432 -U ${var.db_username} -d ${var.db_name}"
  "postgres_user_password":"${var.db_username}, ${var.db_password}"
  EOT
}