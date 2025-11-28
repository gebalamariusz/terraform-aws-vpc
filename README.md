# AWS VPC Terraform Module

[![CI](https://github.com/gebalamariusz/terraform-aws-vpc/actions/workflows/ci.yml/badge.svg)](https://github.com/gebalamariusz/terraform-aws-vpc/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/gebalamariusz/terraform-aws-vpc?display_name=tag&sort=semver)](https://github.com/gebalamariusz/terraform-aws-vpc/releases)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.7-purple.svg)](https://www.terraform.io/)

Terraform module to create AWS VPC with optional Internet Gateway, DHCP Options, VPC Flow Logs, and Secondary CIDR blocks.

## Features

- Create new VPC or reference existing one
- Optional Internet Gateway
- Optional custom DHCP Options Set
- VPC Flow Logs to CloudWatch or S3
- Secondary CIDR blocks support
- Consistent tagging and naming

## Usage

### Basic VPC

```hcl
module "vpc" {
  source  = "hait/vpc/aws"
  version = "1.0.0"

  name       = "my-app"
  cidr_block = "10.0.0.0/16"
}
```

### VPC with Flow Logs

```hcl
module "vpc" {
  source  = "hait/vpc/aws"
  version = "1.0.0"

  name       = "my-app"
  cidr_block = "10.0.0.0/16"

  enable_flow_logs                                 = true
  flow_logs_destination_type                       = "cloud-watch-logs"
  create_flow_logs_cloudwatch_log_group            = true
  flow_logs_cloudwatch_log_group_retention_in_days = 30
}
```

### VPC with Secondary CIDRs

```hcl
module "vpc" {
  source  = "hait/vpc/aws"
  version = "1.0.0"

  name       = "my-app"
  cidr_block = "10.0.0.0/16"

  secondary_cidr_blocks = [
    "10.1.0.0/16",
    "10.2.0.0/16"
  ]
}
```

### Reference Existing VPC

```hcl
module "vpc" {
  source  = "hait/vpc/aws"
  version = "1.0.0"

  name       = "existing"
  create_vpc = false
  vpc_id     = "vpc-0abc123def456789"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.7 |
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name for VPC and prefix for related resources | `string` | n/a | yes |
| environment | Environment name (used in naming/tagging if provided) | `string` | `""` | no |
| tags | Additional tags for all resources | `map(string)` | `{}` | no |
| create_vpc | Create a new VPC or reference existing | `bool` | `true` | no |
| vpc_id | ID of existing VPC (when create_vpc = false) | `string` | `""` | no |
| cidr_block | IPv4 CIDR block for VPC | `string` | `""` | no |
| secondary_cidr_blocks | List of secondary CIDR blocks | `list(string)` | `[]` | no |
| instance_tenancy | Tenancy option (default or dedicated) | `string` | `"default"` | no |
| enable_dns_support | Enable DNS support | `bool` | `true` | no |
| enable_dns_hostnames | Enable DNS hostnames | `bool` | `true` | no |
| create_igw | Create Internet Gateway | `bool` | `true` | no |
| enable_dhcp_options | Create custom DHCP options | `bool` | `false` | no |
| enable_flow_logs | Enable VPC Flow Logs | `bool` | `false` | no |
| flow_logs_destination_type | Flow Logs destination (cloud-watch-logs or s3) | `string` | `"cloud-watch-logs"` | no |

See [variables.tf](variables.tf) for all available inputs.

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| vpc_arn | The ARN of the VPC |
| vpc_cidr_block | The CIDR block of the VPC |
| all_cidr_blocks | All CIDR blocks (primary + secondary) |
| internet_gateway_id | The ID of the Internet Gateway |
| vpc_default_security_group_id | The ID of the default security group |
| vpc_default_route_table_id | The ID of the default route table |
| dhcp_options_id | The ID of the DHCP Options Set |
| flow_log_id | The ID of the VPC Flow Log |

See [outputs.tf](outputs.tf) for all available outputs.

## Examples

- [Simple VPC](https://github.com/gebalamariusz/hait-terraform-modules/tree/main/examples/vpc-simple) - Various VPC configurations

## License

MIT Licensed. See [LICENSE](LICENSE) for full details.

## Author

**HAIT** - [haitmg.pl](https://haitmg.pl)
