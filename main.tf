################################################################################
# Local Variables
################################################################################

locals {
  name_prefix = var.environment != "" ? "${var.name}-${var.environment}" : var.name

  common_tags = merge(
    {
      ManagedBy = "terraform"
      Module    = "vpc"
    },
    var.environment != "" ? { Environment = var.environment } : {},
    var.tags
  )

  # Use created VPC or existing VPC
  vpc_id = var.create_vpc ? aws_vpc.this[0].id : data.aws_vpc.this[0].id

  # Primary CIDR block
  vpc_cidr_block = var.create_vpc ? aws_vpc.this[0].cidr_block : data.aws_vpc.this[0].cidr_block

  # All CIDR blocks (primary + secondary) - useful for security groups and NACLs
  # For existing VPC, we extract all CIDRs from cidr_block_associations
  all_cidr_blocks = var.create_vpc ? concat(
    [aws_vpc.this[0].cidr_block],
    var.secondary_cidr_blocks
  ) : [for assoc in data.aws_vpc.this[0].cidr_block_associations : assoc.cidr_block]

  # Secondary CIDR blocks for existing VPC (all except primary)
  existing_vpc_secondary_cidrs = var.create_vpc ? [] : [
    for assoc in data.aws_vpc.this[0].cidr_block_associations :
    assoc.cidr_block if assoc.cidr_block != data.aws_vpc.this[0].cidr_block
  ]

  flow_logs_iam_role_arn = var.enable_flow_logs && var.flow_logs_destination_type == "cloud-watch-logs" ? (
    var.create_flow_logs_iam_role ? aws_iam_role.flow_logs[0].arn : var.flow_logs_iam_role_arn
  ) : null

  flow_logs_destination_arn = var.enable_flow_logs ? (
    var.flow_logs_destination_type == "cloud-watch-logs" && var.create_flow_logs_cloudwatch_log_group ? aws_cloudwatch_log_group.flow_logs[0].arn : var.flow_logs_destination_arn
  ) : null
}

################################################################################
# VPC
################################################################################

resource "aws_vpc" "this" {
  count = var.create_vpc ? 1 : 0

  cidr_block                           = var.cidr_block
  instance_tenancy                     = var.instance_tenancy
  enable_dns_support                   = var.enable_dns_support
  enable_dns_hostnames                 = var.enable_dns_hostnames
  enable_network_address_usage_metrics = var.enable_network_address_usage_metrics

  tags = merge(
    local.common_tags,
    {
      Name = var.name
    }
  )

  lifecycle {
    precondition {
      condition     = var.cidr_block != ""
      error_message = "cidr_block is required when create_vpc = true."
    }
  }
}

data "aws_vpc" "this" {
  count = var.create_vpc ? 0 : 1

  id = var.vpc_id

  lifecycle {
    precondition {
      condition     = var.vpc_id != ""
      error_message = "vpc_id is required when create_vpc = false."
    }
  }
}

################################################################################
# Existing VPC Data Sources
# These data sources fetch additional information about existing VPCs
# that is not available directly from the aws_vpc data source
################################################################################

data "aws_security_group" "default" {
  count = var.create_vpc ? 0 : 1

  filter {
    name   = "group-name"
    values = ["default"]
  }

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_route_table" "default" {
  count = var.create_vpc ? 0 : 1

  filter {
    name   = "association.main"
    values = ["true"]
  }

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_network_acls" "default" {
  count = var.create_vpc ? 0 : 1

  filter {
    name   = "default"
    values = ["true"]
  }

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

################################################################################
# Secondary CIDR Blocks
################################################################################

resource "aws_vpc_ipv4_cidr_block_association" "this" {
  for_each = var.create_vpc ? toset(var.secondary_cidr_blocks) : toset([])

  vpc_id     = local.vpc_id
  cidr_block = each.value
}

################################################################################
# Internet Gateway
################################################################################

resource "aws_internet_gateway" "this" {
  count = var.create_vpc && var.create_igw ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-igw"
    }
  )
}

################################################################################
# DHCP Options
################################################################################

resource "aws_vpc_dhcp_options" "this" {
  count = var.create_vpc && var.enable_dhcp_options ? 1 : 0

  domain_name          = var.dhcp_options_domain_name != "" ? var.dhcp_options_domain_name : null
  domain_name_servers  = var.dhcp_options_domain_name_servers
  ntp_servers          = length(var.dhcp_options_ntp_servers) > 0 ? var.dhcp_options_ntp_servers : null
  netbios_name_servers = length(var.dhcp_options_netbios_name_servers) > 0 ? var.dhcp_options_netbios_name_servers : null
  netbios_node_type    = var.dhcp_options_netbios_node_type

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-dhcp-options"
    }
  )
}

resource "aws_vpc_dhcp_options_association" "this" {
  count = var.create_vpc && var.enable_dhcp_options ? 1 : 0

  vpc_id          = local.vpc_id
  dhcp_options_id = aws_vpc_dhcp_options.this[0].id
}

################################################################################
# VPC Flow Logs
################################################################################

resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs && var.flow_logs_destination_type == "cloud-watch-logs" && var.create_flow_logs_cloudwatch_log_group ? 1 : 0

  name              = "/aws/vpc-flow-logs/${local.name_prefix}"
  retention_in_days = var.flow_logs_cloudwatch_log_group_retention_in_days
  kms_key_id        = var.flow_logs_cloudwatch_log_group_kms_key_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-flow-logs"
    }
  )
}

data "aws_iam_policy_document" "flow_logs_assume_role" {
  count = var.enable_flow_logs && var.flow_logs_destination_type == "cloud-watch-logs" && var.create_flow_logs_iam_role ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs && var.flow_logs_destination_type == "cloud-watch-logs" && var.create_flow_logs_iam_role ? 1 : 0

  name               = "${local.name_prefix}-vpc-flow-logs-role"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_assume_role[0].json

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-vpc-flow-logs-role"
    }
  )
}

data "aws_iam_policy_document" "flow_logs_permissions" {
  count = var.enable_flow_logs && var.flow_logs_destination_type == "cloud-watch-logs" && var.create_flow_logs_iam_role ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs && var.flow_logs_destination_type == "cloud-watch-logs" && var.create_flow_logs_iam_role ? 1 : 0

  name   = "${local.name_prefix}-vpc-flow-logs-policy"
  role   = aws_iam_role.flow_logs[0].id
  policy = data.aws_iam_policy_document.flow_logs_permissions[0].json
}

resource "aws_flow_log" "this" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id                   = local.vpc_id
  traffic_type             = var.flow_logs_traffic_type
  log_destination_type     = var.flow_logs_destination_type
  log_destination          = local.flow_logs_destination_arn
  iam_role_arn             = local.flow_logs_iam_role_arn
  max_aggregation_interval = var.flow_logs_max_aggregation_interval

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-flow-log"
    }
  )

  depends_on = [
    aws_cloudwatch_log_group.flow_logs,
    aws_iam_role_policy.flow_logs,
  ]
}
