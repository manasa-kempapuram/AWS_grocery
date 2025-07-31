##################
# EC2 Key Pair Name
##################
variable "key_pair_name" {
  description = "EC2 key pair name used for SSH access to instances"
  type        = string
}

##################
# RDS Username
##################
variable "db_username" {
  description = "Master username for the RDS database"
  type        = string
  sensitive   = true
}

##################
# RDS Password
##################
variable "db_password" {
  description = "Master password for the RDS database"
  type        = string
  sensitive   = true
}
