

/*===========================
          Root file
============================*/

# ------- Providers -------
provider "aws" {
  region             = var.aws_region

  # provider level tags - yet inconsistent when executing 
  # default_tags {
  #   tags = {
  #     Created_by = "Terraform"
  #     Project    = "AWS_demo_fullstack_devops"
  #   }
  # }
}
terraform {
  backend "s3" {
       bucket = "dsinfra"
       key    = "sample/terraform.tfstate"
       region = "ap-south-1"
  }
}
data "aws_vpc" "existing" {
  id = "vpc-00d22b17ac6cf513f"  
}


variable "public_subnet" {
  type        = list(string)
  description = "List of private client subnet IDs"
  default     = ["subnet-063de474d277be466", "subnet-0094dfe3595e342c7"]
}
variable "private_client_subnet_ids" {
  type        = list(string)
  description = "List of private client subnet IDs"
  default     = ["subnet-059152206eab04219", "subnet-070f4a30ad7807fa9"]
}
variable "private_server_subnet_ids" {
  type        = list(string)
  description = "List of private client subnet IDs"
  default     = ["subnet-0fe3f1c09dbf1c2dd", "subnet-0d32a04344040b064"]
}

# ------- Random numbers intended to be used as unique identifiers for resources -------
resource "random_id" "RANDOM_ID" {
  byte_length = "2"
}

# ------- Account ID -------
data "aws_caller_identity" "id_current_account" {}



# ------- Creating Target Group for the server ALB blue environment -------
module "target_group_server_blue" {
  source              = "../Modules/ALB"
  create_target_group = true
  name                = "tg-${var.environment_name}-s-b"
  port                = 80
  protocol            = "HTTP"
  vpc                 = data.aws_vpc.existing.id
  tg_type             = "ip"
  health_check_path   = "/status"
  health_check_port   = var.port_app_server
}

# ------- Creating Target Group for the server ALB green environment -------
module "target_group_server_green" {
  source              = "../Modules/ALB"
  create_target_group = true
  name                = "tg-${var.environment_name}-s-g"
  port                = 80
  protocol            = "HTTP"
  vpc                 = data.aws_vpc.existing.id
  tg_type             = "ip"
  health_check_path   = "/status"
  health_check_port   = var.port_app_server
}

# ------- Creating Target Group for the client ALB blue environment -------
module "target_group_client_blue" {
  source              = "../Modules/ALB"
  create_target_group = true
  name                = "tg-${var.environment_name}-c-b"
  port                = 80
  protocol            = "HTTP"
  vpc                 = data.aws_vpc.existing.id
  tg_type             = "ip"
  health_check_path   = "/"
  health_check_port   = var.port_app_client
}

# ------- Creating Target Group for the client ALB green environment -------
module "target_group_client_green" {
  source              = "../Modules/ALB"
  create_target_group = true
  name                = "tg-${var.environment_name}-c-g"
  port                = 80
  protocol            = "HTTP"
  vpc                 = data.aws_vpc.existing.id
  tg_type             = "ip"
  health_check_path   = "/"
  health_check_port   = var.port_app_client
}

# ------- Creating Security Group for the server ALB -------
module "security_group_alb_server" {
  source              = "../Modules/SecurityGroup"
  name                = "alb-${var.environment_name}-server"
  description         = "Controls access to the server ALB"
  vpc_id              = data.aws_vpc.existing.id
  cidr_blocks_ingress = ["0.0.0.0/0"]
  ingress_port        = 80
}

# ------- Creating Security Group for the client ALB -------
module "security_group_alb_client" {
  source              = "../Modules/SecurityGroup"
  name                = "alb-${var.environment_name}-client"
  description         = "Controls access to the client ALB"
  vpc_id              = data.aws_vpc.existing.id
  cidr_blocks_ingress = ["0.0.0.0/0"]
  ingress_port        = 80
}

# ------- Creating Server Application ALB -------
module "alb_server" {
  source         = "../Modules/ALB"
  create_alb     = true
  name           = "${var.environment_name}-ser"
  subnets        = var.public_subnet
  security_group = module.security_group_alb_server.sg_id
  target_group   = module.target_group_server_blue.arn_tg
}

# ------- Creating Client Application ALB -------
module "alb_client" {
  source         = "../Modules/ALB"
  create_alb     = true
  name           = "${var.environment_name}-cli"
  subnets        = var.public_subnet
  security_group = module.security_group_alb_client.sg_id
  target_group   = module.target_group_client_blue.arn_tg
}

# ------- ECS Role -------
data "aws_iam_role" "ecs_task_execution_role" {
  name = "ECS-task-excecution-Role"
}

data "aws_iam_role" "ecs_task_role" {
  name = "ECS-task-Role"
}

# # ------- Creating server ECR Repository to store Docker Images -------
module "ecr_server" {
  source = "../Modules/ECR"
  name   = "repo-server"
}

# # ------- Creating client ECR Repository to store Docker Images -------
module "ecr_client" {
  source = "../Modules/ECR"
  name   = "repo-client"
}

# ------- Creating ECS Task Definition for the server -------
module "ecs_taks_definition_server" {
  source             = "../Modules/ECS/TaskDefinition"
  name               = "${var.environment_name}-server"
  container_name     = var.container_name["server"]
  execution_role_arn = data.aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = data.aws_iam_role.ecs_task_role.arn
  cpu                = 1024
  memory             = "2048"
  docker_repo        = "851725235990.dkr.ecr.ap-south-1.amazonaws.com/fab_dev:158"
  region             = var.aws_region
  container_port     = var.port_app_server
}

# ------- Creating ECS Task Definition for the client -------
module "ecs_taks_definition_client" {
  source             = "../Modules/ECS/TaskDefinition"
  name               = "${var.environment_name}-client"
  container_name     = var.container_name["client"]
  execution_role_arn = data.aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = data.aws_iam_role.ecs_task_role.arn
  cpu                = 1024
  memory             = "2048"
  docker_repo        = "851725235990.dkr.ecr.ap-south-1.amazonaws.com/fabfe:11"
  region             = var.aws_region
  container_port     = var.port_app_client
}

# ------- Creating a server Security Group for ECS TASKS -------
module "security_group_ecs_task_server" {
  source          = "../Modules/SecurityGroup"
  name            = "ecs-task-${var.environment_name}-server"
  description     = "Controls access to the server ECS task"
  vpc_id          = data.aws_vpc.existing.id
  ingress_port    = var.port_app_server
  security_groups = [module.security_group_alb_server.sg_id]
}
# ------- Creating a client Security Group for ECS TASKS -------
module "security_group_ecs_task_client" {
  source          = "../Modules/SecurityGroup"
  name            = "ecs-task-${var.environment_name}-client"
  description     = "Controls access to the client ECS task"
  vpc_id          = data.aws_vpc.existing.id
  ingress_port    = var.port_app_client
  security_groups = [module.security_group_alb_client.sg_id]
}

# ------- Creating ECS Cluster -------
module "ecs_cluster" {
  source = "../Modules/ECS/Cluster"
  name   = var.environment_name
}

# ------- Creating ECS Service server -------
module "ecs_service_server" {
  depends_on          = [module.alb_server]
  source              = "../Modules/ECS/Service"
  name                = "${var.environment_name}-server"
  desired_tasks       = 1
  arn_security_group  = module.security_group_ecs_task_server.sg_id
  ecs_cluster_id      = module.ecs_cluster.ecs_cluster_id
  arn_target_group    = module.target_group_server_blue.arn_tg
  arn_task_definition = module.ecs_taks_definition_server.arn_task_definition
  subnets_id          = var.private_server_subnet_ids
  container_port      = var.port_app_server
  container_name      = var.container_name["server"]
}

# ------- Creating ECS Service client -------
module "ecs_service_client" {
  depends_on          = [module.alb_client]
  source              = "../Modules/ECS/Service"
  name                = "${var.environment_name}-client"
  desired_tasks       = 1
  arn_security_group  = module.security_group_ecs_task_client.sg_id
  ecs_cluster_id      = module.ecs_cluster.ecs_cluster_id
  arn_target_group    = module.target_group_client_blue.arn_tg
  arn_task_definition = module.ecs_taks_definition_client.arn_task_definition
  subnets_id          = var.private_client_subnet_ids
  container_port      = var.port_app_client
  container_name      = var.container_name["client"]
}

# ------- Creating ECS Autoscaling policies for the server application -------
module "ecs_autoscaling_server" {
  depends_on   = [module.ecs_service_server]
  source       = "../Modules/ECS/Autoscaling"
  name         = "${var.environment_name}-server"
  cluster_name = module.ecs_cluster.ecs_cluster_name
  min_capacity = 1
  max_capacity = 4
}

# ------- Creating ECS Autoscaling policies for the client application -------
module "ecs_autoscaling_client" {
  depends_on   = [module.ecs_service_client]
  source       = "../Modules/ECS/Autoscaling"
  name         = "${var.environment_name}-client"
  cluster_name = module.ecs_cluster.ecs_cluster_name
  min_capacity = 1
  max_capacity = 4
}

# ------- CodePipeline -------

# # ------- Creating Bucket to store CodePipeline artifacts -------
module "s3_codepipeline" {
  source      = "../Modules/S3"
  bucket_name = "codepipeline-${var.aws_region}-${random_id.RANDOM_ID.hex}"
}

# ------- Creating IAM roles used during the pipeline excecution -------

data "aws_iam_role" "devops_role" {
  name = "DevOps-Role"
}

# ------- Creating a SNS topic -------
module "sns" {
  source   = "../Modules/SNS"
  sns_name = "sns-${var.environment_name}"
}

# ------- Creating the server CodeBuild project -------
module "codebuild_server" {
  source                 = "../Modules/CodeBuild"
  name                   = "codebuild-${var.environment_name}-server"
  iam_role               = data.aws_iam_role.devops_role.arn
  region                 = var.aws_region
  account_id             = data.aws_caller_identity.id_current_account.account_id
  ecr_repo_url           = module.ecr_server.ecr_repository_url
  folder_path            = var.folder_path_server
  buildspec_path         = var.buildspec_path
  task_definition_family = module.ecs_taks_definition_server.task_definition_family
  container_name         = var.container_name["server"]
  service_port           = var.port_app_server
  ecs_role               = var.iam_role_name["ecs"]
  ecs_task_role          = var.iam_role_name["ecs_task_role"]
}

# ------- Creating the client CodeBuild project -------
module "codebuild_client" {
  source                 = "../Modules/CodeBuild"
  name                   = "codebuild-${var.environment_name}-client"
  iam_role               = data.aws_iam_role.devops_role.arn
  region                 = var.aws_region
  account_id             = data.aws_caller_identity.id_current_account.account_id
  ecr_repo_url           = module.ecr_client.ecr_repository_url
  folder_path            = var.folder_path_client
  buildspec_path         = var.buildspec_path
  task_definition_family = module.ecs_taks_definition_client.task_definition_family
  container_name         = var.container_name["client"]
  service_port           = var.port_app_client
  ecs_role               = var.iam_role_name["ecs"]
  server_alb_url         = module.alb_server.dns_alb
}

# ------- Creating the server CodeDeploy project -------
module "codedeploy_server" {
  source          = "../Modules/CodeDeploy"
  name            = "Deploy-${var.environment_name}-server"
  ecs_cluster     = module.ecs_cluster.ecs_cluster_name
  ecs_service     = module.ecs_service_server.ecs_service_name
  alb_listener    = module.alb_server.arn_listener
  tg_blue         = module.target_group_server_blue.tg_name
  tg_green        = module.target_group_server_green.tg_name
  sns_topic_arn   = module.sns.sns_arn
  codedeploy_role = module.codedeploy_role.arn_role_codedeploy
}

# ------- Creating the client CodeDeploy project -------
module "codedeploy_client" {
  source          = "../Modules/CodeDeploy"
  name            = "Deploy-${var.environment_name}-client"
  ecs_cluster     = module.ecs_cluster.ecs_cluster_name
  ecs_service     = module.ecs_service_client.ecs_service_name
  alb_listener    = module.alb_client.arn_listener
  tg_blue         = module.target_group_client_blue.tg_name
  tg_green        = module.target_group_client_green.tg_name
  sns_topic_arn   = module.sns.sns_arn
  codedeploy_role = module.codedeploy_role.arn_role_codedeploy
}

# ------- Creating CodePipeline -------

module "codepipeline" {
  source                   = "../Modules/CodePipeline"
  name                     = "pipeline-${var.environment_name}"
  pipe_role                = data.aws_iam_role.devops_role.arn
  s3_bucket                = module.s3_codepipeline.s3_bucket_id
  repo_owner               = var.repository_owner
  repo_name                = var.repository_name
  branch                   = var.repository_branch
  codebuild_project = module.codebuild_client.project_id
  app_name         = module.codedeploy_client.application_name
  deployment_group  = module.codedeploy_client.deployment_group_name


}


module "codepipeline_server" {
  source                   = "../Modules/CodePipeline"
  name                     = "pipeline-${var.environment_name}-backend"
  pipe_role                = data.aws_iam_role.devops_role.arn
  s3_bucket                = module.s3_codepipeline.s3_bucket_id
  repo_owner               = var.repository_owner
  repo_name                = var.repository_name_backend
  branch                   = var.repository_branch
  codebuild_project = module.codebuild_server.project_id
  app_name          = module.codedeploy_server.application_name
  deployment_group  = module.codedeploy_server.deployment_group_name



}



# ------- Creating Bucket to store assets accessed by the Back-end -------
# module "s3_assets" {
#   source      = "../Modules/S3"
#   bucket_name = "assets-${var.aws_region}-${random_id.RANDOM_ID.hex}"
# }

# ------- Creating Dynamodb table by the Back-end -------
# module "dynamodb_table" {
#   source = "../Modules/Dynamodb"
#   name   = "assets-table-${var.environment_name}"
# }
