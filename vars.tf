variable "region" {
  type = "string"
  default = "us-east-1"
}

variable "ssh_public_key" {
  type = "string"
  default = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key" {
  type = "string"
  default = "~/.ssh/id_rsa"
}

variable "env_tag" {
  type = "string"
  default = "default"
}

variable "instance_type" {
  type = "string"
  default = "c4.xlarge"
}

variable "spot_price" {
  default = "0.07"
}

variable "workers_count" {
  default = 1
}

terraform {
  backend "s3" {
    bucket = "ql-us-east-1-terraform"
    key = "dask"
    region = "us-east-1"
  }
}