################################################################################
# General
################################################################################

variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod). Optional - used in resource naming if provided."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# VPC
################################################################################

variable "create_vpc" {
  description = "Create a new VPC. If false, vpc_id must be provided to reference an existing VPC"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "ID of an existing VPC to use (required when create_vpc = false)"
  type        = string
  default     = ""

  validation {
    condition     = var.vpc_id == "" || can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "VPC ID must be a valid vpc-* identifier."
  }
}

variable "cidr_block" {
  description = "The IPv4 CIDR block for the VPC (required when create_vpc = true)"
  type        = string
  default     = ""

  validation {
    condition     = var.cidr_block == "" || can(cidrhost(var.cidr_block, 0))
    error_message = "Must be a valid IPv4 CIDR block."
  }
}

variable "instance_tenancy" {
  description = "A tenancy option for instances launched into the VPC (default or dedicated)"
  type        = string
  default     = "default"

  validation {
    condition     = contains(["default", "dedicated"], var.instance_tenancy)
    error_message = "Instance tenancy must be 'default' or 'dedicated'."
  }
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_network_address_usage_metrics" {
  description = "Enable Network Address Usage metrics for the VPC"
  type        = bool
  default     = false
}

variable "secondary_cidr_blocks" {
  description = "List of secondary IPv4 CIDR blocks to associate with the VPC. Useful when you need additional IP ranges."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.secondary_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All secondary CIDR blocks must be valid IPv4 CIDR blocks."
  }
}

################################################################################
# Internet Gateway
################################################################################

variable "create_igw" {
  description = "Create an Internet Gateway for the VPC"
  type        = bool
  default     = true
}

################################################################################
# DHCP Options
################################################################################

variable "enable_dhcp_options" {
  description = "Create custom DHCP options set for the VPC"
  type        = bool
  default     = false
}

variable "dhcp_options_domain_name" {
  description = "Domain name for DHCP options"
  type        = string
  default     = ""
}

variable "dhcp_options_domain_name_servers" {
  description = "List of DNS server addresses for DHCP options"
  type        = list(string)
  default     = ["AmazonProvidedDNS"]
}

variable "dhcp_options_ntp_servers" {
  description = "List of NTP server addresses for DHCP options"
  type        = list(string)
  default     = []
}

variable "dhcp_options_netbios_name_servers" {
  description = "List of NetBIOS name server addresses for DHCP options"
  type        = list(string)
  default     = []
}

variable "dhcp_options_netbios_node_type" {
  description = "NetBIOS node type (1, 2, 4, or 8)"
  type        = number
  default     = null

  validation {
    condition     = var.dhcp_options_netbios_node_type == null || try(contains([1, 2, 4, 8], var.dhcp_options_netbios_node_type), false)
    error_message = "NetBIOS node type must be 1, 2, 4, or 8."
  }
}

################################################################################
# VPC Flow Logs
################################################################################

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

variable "flow_logs_destination_type" {
  description = "The type of destination for VPC Flow Logs (cloud-watch-logs or s3)"
  type        = string
  default     = "cloud-watch-logs"

  validation {
    condition     = contains(["cloud-watch-logs", "s3"], var.flow_logs_destination_type)
    error_message = "Flow logs destination type must be 'cloud-watch-logs' or 's3'."
  }
}

variable "flow_logs_destination_arn" {
  description = "The ARN of the destination for VPC Flow Logs (CloudWatch Log Group or S3 bucket)"
  type        = string
  default     = ""
}

variable "flow_logs_traffic_type" {
  description = "The type of traffic to capture (ACCEPT, REJECT, or ALL)"
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.flow_logs_traffic_type)
    error_message = "Traffic type must be 'ACCEPT', 'REJECT', or 'ALL'."
  }
}

variable "flow_logs_max_aggregation_interval" {
  description = "The maximum interval of time (in seconds) during which flow logs are captured"
  type        = number
  default     = 600

  validation {
    condition     = contains([60, 600], var.flow_logs_max_aggregation_interval)
    error_message = "Max aggregation interval must be 60 or 600 seconds."
  }
}

variable "create_flow_logs_cloudwatch_log_group" {
  description = "Create a CloudWatch Log Group for VPC Flow Logs (only if destination_type is cloud-watch-logs)"
  type        = bool
  default     = true
}

variable "flow_logs_cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain VPC Flow Logs in CloudWatch"
  type        = number
  default     = 30

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.flow_logs_cloudwatch_log_group_retention_in_days)
    error_message = "Retention days must be a valid CloudWatch Logs retention value."
  }
}

variable "flow_logs_cloudwatch_log_group_kms_key_id" {
  description = "The ARN of the KMS key to use for encrypting VPC Flow Logs in CloudWatch"
  type        = string
  default     = null
}

variable "create_flow_logs_iam_role" {
  description = "Create an IAM role for VPC Flow Logs to CloudWatch (only if destination_type is cloud-watch-logs)"
  type        = bool
  default     = true
}

variable "flow_logs_iam_role_arn" {
  description = "The ARN of an existing IAM role for VPC Flow Logs (if not creating a new one)"
  type        = string
  default     = ""
}
