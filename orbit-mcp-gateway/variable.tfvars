environment = "dev"
region      = "us-east-1"

# orbit-core outputs se fill in these values
vpc_id             = ""
private_subnet_ids = ["", ""]

alb_security_group_id      = ""
ecs_security_group_id      = ""
ecs_task_execution_role_arn = ""
ecs_task_role_arn           = ""

alb_listener_arn       = ""
mcp_gateway_hostname   = ""
listener_rule_priority = 200

ecr_repository_uri             = ""
existing_cluster_name          = "orbit-cluster-dev"
service_discovery_namespace_id = ""
service_discovery_namespace_name = "orbit.local"

update_ssm_parameter = false