# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-28

### Added

- Initial release of AWS VPC Terraform module
- VPC creation with configurable CIDR block
- Optional Internet Gateway
- Optional custom DHCP Options Set with domain name servers, domain name, NTP servers, and NetBIOS settings
- VPC Flow Logs support with CloudWatch Logs or S3 destination
- Secondary CIDR blocks support
- Reference existing VPC mode (`create_vpc = false`)
- Consistent tagging with `ManagedBy`, `Module`, and optional `Environment` tags
- Comprehensive outputs including VPC ID, ARN, CIDR blocks, IGW ID, and default resources
- CI pipeline with terraform fmt, validate, tflint, and tfsec
- MIT License

[1.0.0]: https://github.com/gebalamariusz/terraform-aws-vpc/releases/tag/v1.0.0
