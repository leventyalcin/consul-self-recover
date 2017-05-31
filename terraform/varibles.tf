variable "aws_key_name" {}

variable "tag_environment" {
  default = "admin"
}

variable "tag_project" {
  default = "consul"
}

variable "tag_service" {
  default = "service-discovery"
}

variable "tag_role" {
  default = "consul"
}

variable "tag_creator" {
  default = ""
}

variable "aws_region" {
  description = "Region for creating the cluster"
  default = "eu-west-1"
}

variable "vpc_id" {
  description = "VPC id for creating the cluster"
  default = "vpc-99999999"
}

variable "aws_amis" {
  description = "Image ami id"
  default = {
    eu-west-1 = "ami-99999999"
  }
}

variable "aws_instance_type" {
  description = "Instance type"
  default = "t2.micro"
}

variable "s3_repo_bucket" {
  description = "S3 bucket for RPM repository"
  default = "my-consul-s3-repo-bucket"
}

variable "cluster_size" {
  description = "Size of the consul cluster size"
  default = "3"
}

variable "subnet_az1_id" {}
variable "subnet_az2_id" {}
variable "subnet_az3_id" {}
