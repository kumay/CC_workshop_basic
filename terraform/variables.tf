# --- Confluent Cloud Credentials ---
variable "confluent_cloud_api_key" {
  description = "The Confluent Cloud API Key (Cloud scope, not Cluster scope)"
  type        = string
  sensitive   = true
}

variable "confluent_cloud_api_secret" {
  description = "The Confluent Cloud API Secret"
  type        = string
  sensitive   = true
}

# --- AWS Configuration ---
variable "aws_region" {
  description = "The AWS region to deploy resources into"
  type        = string
  default     = "us-east-1" # Tokyo
}

variable "aws_ami_id" {
  description = "The AMI ID for the EC2 instance (Default: Amazon Linux 2023 in Tokyo)"
  type        = string
  default     = "ami-08a70659c7161832e" 
}

variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
  default     = "t3.micro"
}

# --- Confluent Resources ---
variable "confluent_env_name" {
  description = "Name of the Confluent Environment"
  type        = string
  default     = "Staging_Env"
}

variable "confluent_cluster_name" {
  description = "Name of the Confluent Cluster"
  type        = string
  default     = "basic_cluster_tokyo"
}

# --- Database Credentials ---
variable "db_name" {
  description = "The name of the database to create"
  type        = string
  default     = "mydb"
}

variable "db_username" {
  description = "Master username for Aurora"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Master password for Aurora"
  type        = string
  sensitive   = true
  # Note: It is best practice NOT to provide a default for passwords.
  # But for this demo request:
  default     = "1234567!Admin"
}

variable "db_version" {
  description = "Postgresql version of Aurora"
  type        = string
  default     = "16.10"
}