environment      = "test"
region           = "us-east-1"
vpc_cidr         = "10.0.0.0/16"
public_subnets   = ["10.0.0.0/24", "10.0.1.0/24"]
private_subnets  = ["10.0.32.0/24", "10.0.33.0/24"]
database_subnets = ["10.0.64.0/24", "10.0.65.0/24"]
name = "orbit"

use_existing_assets_bucket   = false
use_existing_audit_bucket    = false
use_existing_rag_bucket      = false
use_existing_datalake_bucket = false

redis_auth_token = "your-redis-auth-token"

# Database variables
db_username = "orbit_admin"  # Generate password: openssl rand -base64 32

templates_bucket = ""


ecr_repository_uri  = ""
container_image_tag = "latest"
acm_certificate_arn = ""
alarm_sns_topic_arn = ""


alert_email = ""

domain_name      = "csiorbit.com"
mcp_gateway_host = ""