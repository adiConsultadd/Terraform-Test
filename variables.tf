variable "aws_region" { type = string }
variable "environment" { type = string }
variable "project_name" { type = string }

# ---- Networking -------------------------------------------
variable "vpc_cidr" { type = string }
variable "public_subnet_cidrs" { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }
variable "availability_zones" { type = list(string) }

# ---- RDS --------------------------------------------------
variable "db_engine" { type = string }
variable "db_instance_class" { type = string }
variable "db_allocated_storage" { type = number }
variable "db_username" { type = string }
variable "db_password" {
  type      = string
  sensitive = true
}
variable "skip_final_snapshot" { type = bool }
variable "db_multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type        = bool
  default     = false
}

# ---- CloudFront -------------------------------------------
variable "cloudfront_price_class" { type = string }
variable "viewer_protocol_policy" { type = string }
variable "default_root_object" { type = string }
variable "cloudfront_enabled" { type = bool }

# ---- EventBridge ------------------------------------------
variable "eventbridge_schedule_expression" { type = string }

# ---- Lambda Layers ----------------------------------
variable "lambda_layers" {
  description = "Configuration for Lambda layers"
  type = map(object({
    source_path         = string
    compatible_runtimes = list(string)
  }))
  default = {}
}

# ---- EC2 --------------------------------------------------
variable "ec2_instance_type" {
  type = string
}
variable "ec2_ami_id" {
  type = string
}
variable "ec2_key_name" {
  type        = string
  description = "Key pair name for EC2 instance access"
}
variable "ssh_access_cidr" {
  type        = string
  description = "CIDR block for SSH access to the EC2 instance"
}

# ---- Static SSM Parameters --------------------------------
variable "google_api_key" {
  type      = string
  sensitive = true
}
variable "openai_api_key" {
  type      = string
  sensitive = true
}

# ---- HigherGov Static SSM Parameters ----------------------
variable "highergov_apibaseurl" { type = string }
variable "highergov_apidocurl" { type = string }
variable "highergov_apikey" {
  type      = string
  sensitive = true
}
variable "highergov_email" { type = string }
variable "highergov_loginurl" { type = string }
variable "highergov_password" {
  type      = string
  sensitive = true
}
variable "highergov_portalurl" { type = string }
variable "search_id" { type = string }