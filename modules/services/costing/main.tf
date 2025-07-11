###############################################################################
# 1. IAM Role (Whole Service)
###############################################################################
locals {
  service_policy_statements = [
    # CloudWatch Logs permissions
    { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] },
    # VPC permissions for Lambda to operate within a VPC
    { Effect = "Allow", Action = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"], Resource = "*" },
    # ElastiCache Serverless permissions - Allows connection to ANY cache
    { Effect = "Allow", Action = ["elasticache:Connect"], Resource = "*" },
    # RDS DB permissions - Allows connection to ANY database
    { Effect = "Allow", Action = ["rds-db:connect"], Resource = "*" }
  ]
}
module "costing_lambda_role" {
  source = "../../base-infra/iam-lambda"

  role_name         = "${var.project_name}-${var.environment}-costing-service-role"
  project_name      = var.project_name
  environment       = var.environment
  policy_statements = local.service_policy_statements
}

###############################################################################
# 2. Lambda function definitions
###############################################################################
locals {
  lambdas = {
    "costing-hourly-wages"                 = { source_dir = "${path.module}/lambda-code/blackbox_hourly_wages_lambda" }
    "costing-hourly-wages-result"          = { source_dir = "${path.module}/lambda-code/blackbox_hourly_wages_result_lambda" }
    "costing-rfp-cost-formating"           = { source_dir = "${path.module}/lambda-code/blackbox_rfp_cost_formating_lambda" }
    "costing-rfp-cost-image-calculation"   = { source_dir = "${path.module}/lambda-code/blackbox_rfp_cost_image_calculation_lambda" }
    "costing-rfp-cost-image-extractor"     = { source_dir = "${path.module}/lambda-code/blackbox_rfp_cost_image_extractor_lambda" }
    "costing-rfp-cost-regenerating"        = { source_dir = "${path.module}/lambda-code/blackbox_rfp_cost_regenerating_lambda" }
    "costing-rfp-infrastructure"           = { source_dir = "${path.module}/lambda-code/blackbox_rfp_infrastructure_lambda" }
    "costing-rfp-license"                  = { source_dir = "${path.module}/lambda-code/blackbox_rfp_license_lambda" }
  }
}

###############################################################################
# 3. Lambda functions (referencing the single service role)
###############################################################################
module "lambda" {
  for_each = local.lambdas
  source   = "../../base-infra/lambda"

  function_name = "${var.project_name}-${var.environment}-${each.key}"
  source_dir    = each.value.source_dir
  
  # All functions now use the SAME role ARN
  lambda_role_arn = module.costing_lambda_role.role_arn

  # VPC config remains the same
  vpc_subnet_ids         = var.private_subnet_ids
  vpc_security_group_ids = [var.lambda_security_group_id]
}

###############################################################################
# 4. State Machines
###############################################################################
module "costing_state_machine_1" {
  source = "../../base-infra/step-function"

  project_name       = var.project_name
  environment        = var.environment
  state_machine_name = "costing-workflow-1"
  definition = templatefile("${path.module}/state-machine-1.tftpl", {
    rfp_infrastructure_lambda_arn  = module.lambda["costing-rfp-infrastructure"].lambda_arn
    rfp_license_lambda_arn         = module.lambda["costing-rfp-license"].lambda_arn
    hourly_wages_lambda_arn        = module.lambda["costing-hourly-wages"].lambda_arn
    hourly_wages_result_lambda_arn = module.lambda["costing-hourly-wages-result"].lambda_arn
  })
}

module "costing_state_machine_2" {
  source = "../../base-infra/step-function"

  project_name       = var.project_name
  environment        = var.environment
  state_machine_name = "costing-workflow-2"
  definition = templatefile("${path.module}/state-machine-2.tftpl", {
    rfp_cost_image_extractor_lambda_arn   = module.lambda["costing-rfp-cost-image-extractor"].lambda_arn
    rfp_cost_image_calculation_lambda_arn = module.lambda["costing-rfp-cost-image-calculation"].lambda_arn
  })
}