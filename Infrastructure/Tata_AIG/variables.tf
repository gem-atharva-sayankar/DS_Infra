

# variable "aws_profile" {
#   description = "The profile name that you have configured in the file .aws/credentials"
#   type        = string
# }

variable "aws_region" {
  description = "The AWS Region in which you want to deploy the resources"
  type        = string
  default     = "ap-south-1"
}

variable "environment_name" {
  description = "The name of your environment"
  type        = string
  default     = "dev"
  validation {
    condition     = length(var.environment_name) < 23
    error_message = "Due the this variable is used for concatenation of names of other resources, the value must have less than 23 characters."
  }
}




variable "port_app_server" {
  description = "The port used by your server application"
  type        = number
  default     = 8501
}



variable "buildspec_path" {
  description = "The location of the buildspec file"
  type        = string
  default     = "buildspec.yml"
}

variable "folder_path_server" {
  description = "The location of the server files"
  type        = string
  default     = "./Code/server/."
}

variable "folder_path_client" {
  description = "The location of the client files"
  type        = string
  default     = "./"
}

variable "container_name" {
  description = "The name of the container of each ECS service"
  type        = map(string)
  default = {
    server = "Container-server"
    client = "Container-client"
  }
}

variable "iam_role_name" {
  description = "The name of the IAM Role for each service"
  type        = map(string)
  default = {
    devops        = "DevOps-Role"
    ecs           = "ECS-task-excecution-Role"
    ecs_task_role = "ECS-task-Role"
    codedeploy    = "CodeDeploy-Role"
  }
}

variable "repository_owner" {
  description = "The name of the owner of the Github repository"
  type        = string
  default     = "Gemini-Solutions"
}

variable "repository_name_backend" {
  description = "The name of the Github repository"
  type        = string
  default     = "customer-onboarding-demo"
}


variable "repository_branch" {
  description = "The name of branch the Github repository, which is going to trigger a new CodePipeline excecution"
  type        = string
  default     = "main"
}
