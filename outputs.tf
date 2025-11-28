################################################################################
# VPC
################################################################################

output "vpc_id" {
  description = "The ID of the VPC"
  value       = local.vpc_id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = var.create_vpc ? aws_vpc.this[0].arn : data.aws_vpc.this[0].arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = local.vpc_cidr_block
}

output "vpc_main_route_table_id" {
  description = "The ID of the main route table associated with this VPC"
  value       = var.create_vpc ? aws_vpc.this[0].main_route_table_id : data.aws_vpc.this[0].main_route_table_id
}

output "vpc_default_security_group_id" {
  description = "The ID of the default security group created with the VPC"
  value       = var.create_vpc ? aws_vpc.this[0].default_security_group_id : data.aws_security_group.default[0].id
}

output "vpc_default_route_table_id" {
  description = "The ID of the default route table of the VPC"
  value       = var.create_vpc ? aws_vpc.this[0].default_route_table_id : data.aws_route_table.default[0].id
}

output "vpc_default_network_acl_id" {
  description = "The ID of the default network ACL of the VPC"
  value       = var.create_vpc ? aws_vpc.this[0].default_network_acl_id : data.aws_network_acls.default[0].ids[0]
}

output "vpc_owner_id" {
  description = "The ID of the AWS account that owns the VPC"
  value       = var.create_vpc ? aws_vpc.this[0].owner_id : data.aws_vpc.this[0].owner_id
}

output "secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks associated with the VPC"
  value       = var.create_vpc ? var.secondary_cidr_blocks : local.existing_vpc_secondary_cidrs
}

output "secondary_cidr_block_associations" {
  description = "Map of secondary CIDR blocks to their association details"
  value = var.create_vpc ? {
    for cidr, assoc in aws_vpc_ipv4_cidr_block_association.this : cidr => {
      id         = assoc.id
      cidr_block = assoc.cidr_block
      vpc_id     = assoc.vpc_id
    }
    } : {
    for assoc in data.aws_vpc.this[0].cidr_block_associations :
    assoc.cidr_block => {
      id         = assoc.association_id
      cidr_block = assoc.cidr_block
      vpc_id     = local.vpc_id
    } if assoc.cidr_block != data.aws_vpc.this[0].cidr_block
  }
}

output "all_cidr_blocks" {
  description = "List of all CIDR blocks (primary + secondary) associated with the VPC"
  value       = local.all_cidr_blocks
}

################################################################################
# Internet Gateway
################################################################################

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = try(aws_internet_gateway.this[0].id, null)
}

output "internet_gateway_arn" {
  description = "The ARN of the Internet Gateway"
  value       = try(aws_internet_gateway.this[0].arn, null)
}

################################################################################
# DHCP Options
################################################################################

output "dhcp_options_id" {
  description = "The ID of the DHCP Options Set"
  value       = var.create_vpc ? try(aws_vpc_dhcp_options.this[0].id, null) : data.aws_vpc.this[0].dhcp_options_id
}

output "dhcp_options_arn" {
  description = "The ARN of the DHCP Options Set"
  value       = try(aws_vpc_dhcp_options.this[0].arn, null)
}

################################################################################
# VPC Flow Logs
################################################################################

output "flow_log_id" {
  description = "The ID of the VPC Flow Log"
  value       = try(aws_flow_log.this[0].id, null)
}

output "flow_log_arn" {
  description = "The ARN of the VPC Flow Log"
  value       = try(aws_flow_log.this[0].arn, null)
}

output "flow_log_cloudwatch_log_group_name" {
  description = "The name of the CloudWatch Log Group for VPC Flow Logs"
  value       = try(aws_cloudwatch_log_group.flow_logs[0].name, null)
}

output "flow_log_cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch Log Group for VPC Flow Logs"
  value       = try(aws_cloudwatch_log_group.flow_logs[0].arn, null)
}

output "flow_log_iam_role_arn" {
  description = "The ARN of the IAM role for VPC Flow Logs"
  value       = try(aws_iam_role.flow_logs[0].arn, null)
}
