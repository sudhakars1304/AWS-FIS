# Variables for AWS FIS Self-Service Terraform Solution
# This file defines all configurable parameters for the FIS experiment infrastructure

# =============================================================================
# GENERAL CONFIGURATION
# =============================================================================

variable "project_name" {
  description = "Name of the project for resource naming and tagging"
  type        = string
  default     = "fis-chaos-engineering"

  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 50
    error_message = "Project name must be between 1 and 50 characters."
  }
}

variable "experiment_name" {
  description = "Name of the FIS experiment"
  type        = string
}


variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-east-1"
}

variable "target_availability_zone" {
  description = "AWS availability zone for resources"
  type        = string
  default     = "ap-east-1a"
}

variable "target_cluster_name" {
  description = "Target EKS cluster name"
  type        = string
}

variable "target_availability_zone_id" {
  description = "Target availability zone for the experiment"
  type        = string
  default     = "ape1-az1"
}


variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}



#variable "team_name" {
#  description = "Name of the team owning the resources"
#  type        = string
#  default     = "platform-engineering"
#}

#variable "cost_center" {
#  description = "Cost center for billing allocation"
#  type        = string
#  default     = "engineering"
#}


# =============================================================================
# EXPERIMENT CONFIGURATION
# =============================================================================

variable "experiment_description" {
  description = "Description of the FIS experiment"
  type        = string
  default     = "Automated chaos engineering experiment for resilience testing"
}

variable "account_targeting" {
  description = "Account targeting mode for multi-account experiments"
  type        = string
  default     = "single-account"

  validation {
    condition     = contains(["single-account", "multi-account"], var.account_targeting)
    error_message = "Account targeting must be either 'single-account' or 'multi-account'."
  }
}

variable "empty_target_resolution_mode" {
  description = "How to handle empty target resolution"
  type        = string
  default     = "skip"

  validation {
    condition     = contains(["fail", "skip"], var.empty_target_resolution_mode)
    error_message = "Empty target resolution mode must be either 'fail' or 'skip'."
  }
}

#variable "actions_mode" {
# description = "Actions mode for the experiment"
# type        = string
# default     = "skip-all-targets-resolution-errors"

# validation {
#   condition     = contains(["skip-all-targets-resolution-errors", "fail-all-targets-resolution-errors"], var.actions_mode)
#   error_message = "Actions mode must be either 'skip-all-targets-resolution-errors' or 'fail-all-targets-resolution-errors'."
# }
#}

# =============================================================================
# ACTION ENABLEMENT FLAGS
# =============================================================================

variable "enable_network_disruption" {
  description = "Enable network disruption action"
  type        = bool
  default     = true
}

variable "enable_asg_capacity_error" {
  description = "Enable Auto Scaling Group capacity error action"
  type        = bool
  default     = true
}

variable "enable_api_capacity_error" {
  description = "Enable API capacity error action"
  type        = bool
  default     = true
}

variable "enable_instance_termination" {
  description = "Enable EC2 instance termination action"
  type        = bool
  default     = true
}



variable "network_disruption_duration" {
  description = "Duration for network disruption (ISO 8601 format, e.g., PT30M for 30 minutes)"
  type        = string
  default     = "PT30M"

  validation {
    condition     = can(regex("^PT[0-9]+[HMS]$", var.network_disruption_duration))
    error_message = "Duration must be in ISO 8601 format (e.g., PT30M, PT1H, PT90S)."
  }
}

variable "network_disruption_scope" {
  description = "Scope of network disruption (all or percentage)"
  type        = string
  default     = "all"

  validation {
    condition     = contains(["all", "percentage"], var.network_disruption_scope)
    error_message = "Network disruption scope must be either 'all' or 'percentage'."
  }
}


# =============================================================================
# ASG CAPACITY ERROR ACTION PARAMETERS
# =============================================================================

variable "asg_capacity_error_duration" {
  description = "Duration for ASG capacity error (ISO 8601 format)"
  type        = string
  default     = "PT30M"

  validation {
    condition     = can(regex("^PT[0-9]+[HMS]$", var.asg_capacity_error_duration))
    error_message = "Duration must be in ISO 8601 format (e.g., PT30M, PT1H, PT90S)."
  }
}

variable "asg_capacity_error_az" {
  description = "Availability Zone identifier for ASG capacity error"
  type        = string
  default     = "ap-east-1a"
}

variable "asg_capacity_error_percentage" {
  description = "Percentage of capacity to affect for ASG errors"
  type        = string
  default     = "100"

  validation {
    condition     = can(tonumber(var.asg_capacity_error_percentage)) && tonumber(var.asg_capacity_error_percentage) >= 0 && tonumber(var.asg_capacity_error_percentage) <= 100
    error_message = "Percentage must be a number between 0 and 100."
  }
}


# =============================================================================
# API CAPACITY ERROR ACTION PARAMETERS
# =============================================================================

variable "api_capacity_error_duration" {
  description = "Duration for API capacity error (ISO 8601 format)"
  type        = string
  default     = "PT30M"

  validation {
    condition     = can(regex("^PT[0-9]+[HMS]$", var.api_capacity_error_duration))
    error_message = "Duration must be in ISO 8601 format (e.g., PT30M, PT1H, PT90S)."
  }
}

variable "api_capacity_error_az" {
  description = "Availability Zone identifier for API capacity error"
  type        = string
  default     = "use1-az1"
}

variable "api_capacity_error_percentage" {
  description = "Percentage of capacity to affect for API errors"
  type        = string
  default     = "100"

  validation {
    condition     = can(tonumber(var.api_capacity_error_percentage)) && tonumber(var.api_capacity_error_percentage) >= 0 && tonumber(var.api_capacity_error_percentage) <= 100
    error_message = "Percentage must be a number between 0 and 100."
  }
}


# =============================================================================
# INSTANCE TERMINATION ACTION PARAMETERS
# =============================================================================

variable "instance_termination_delay" {
  description = "Delay in minutes before terminating instances (0 for no delay)"
  type        = number
  default     = 2

  validation {
    condition     = var.instance_termination_delay >= 0 && var.instance_termination_delay <= 60
    error_message = "Instance termination delay must be between 0 and 60 minutes."
  }
}


# =============================================================================
# TARGET CONFIGURATION - AUTO SCALING GROUPS
# =============================================================================

variable "asg_selection_mode" {
  description = "Selection mode for Auto Scaling Group targets"
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ALL", "COUNT", "PERCENT"], split("(", var.asg_selection_mode)[0])
    error_message = "Selection mode must be ALL, COUNT(n), or PERCENT(n)."
  }
}

#variable "asg_target_tags" {
#  description = "Tags to identify Auto Scaling Group targets"
#  type        = map(string)
#  default = {
#    "Environment" = "dev"
#    "Application" = "web"
#  }
#}

variable "asg_target_filters" {
  description = "Filters for Auto Scaling Group targets"
  type = list(object({
    path   = string
    values = list(string)
  }))
  default = []
}

# =============================================================================
# TARGET CONFIGURATION - IAM ROLES
# =============================================================================

variable "iam_role_selection_mode" {
  description = "Selection mode for IAM role targets"
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ALL", "COUNT", "PERCENT"], split("(", var.iam_role_selection_mode)[0])
    error_message = "Selection mode must be ALL, COUNT(n), or PERCENT(n)."
  }
}

variable "iam_role_target_arns" {
  description = "List of IAM role ARNs to target"
  type        = list(string)
  default     = ["iam-role-fis-nonprod"]
}

# FIXED: Changed from empty map to actual tags for IAM role targeting
#variable "iam_role_target_tags" {
#  description = "Tags to identify IAM role targets"
#  type        = map(string)
#  default = {
#    "Environment" = "dev"
#    "FISEnabled"  = "true"
#  }
#}

# =============================================================================
# TARGET CONFIGURATION - EC2 INSTANCES
# =============================================================================

variable "instance_selection_mode" {
  description = "Selection mode for EC2 instance targets"
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ALL", "COUNT", "PERCENT"], split("(", var.instance_selection_mode)[0])
    error_message = "Selection mode must be ALL, COUNT(n), or PERCENT(n)."
  }
}

#variable "instance_target_tags" {
#  description = "Tags to identify EC2 instance targets"
#  type        = map(string)
#  default = {
#    "Environment" = "dev"
#    "ChaosReady"  = "true"
#  }
#}

#variable "instance_target_filters" {
#  description = "Filters for EC2 instance targets"
#  type = list(object({
#    path   = string
#    values = list(string)
#  }))
#  default = [
#    {
#      path   = "State.Name"
#      values = ["running"]
#    },
#    {
#      path   = "Placement.AvailabilityZone"
#      values = [var.target_availability_zone]
#    }
#  ]
#}

# =============================================================================
# TARGET CONFIGURATION - SUBNETS
# =============================================================================

variable "subnet_selection_mode" {
  description = "Selection mode for subnet targets"
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ALL", "COUNT", "PERCENT"], split("(", var.subnet_selection_mode)[0])
    error_message = "Selection mode must be ALL, COUNT(n), or PERCENT(n)."
  }
}

variable "subnet_target_arns" {
  description = "List of subnet ARNs to target"
  type        = list(string)
  default     = []
}

variable "subnet_target_tags" {
  description = "Tags to identify subnet targets"
  type        = map(string)
  default = {
    "Environment" = "dev"
  }
}

# =============================================================================
# STOP CONDITIONS
# =============================================================================

variable "create_stop_condition_alarm" {
  description = "Create a CloudWatch alarm as stop condition"
  type        = bool
  default     = false
}

variable "stop_condition_cpu_threshold" {
  description = "CPU threshold for stop condition alarm"
  type        = number
  default     = 80

  validation {
    condition     = var.stop_condition_cpu_threshold >= 0 && var.stop_condition_cpu_threshold <= 100
    error_message = "CPU threshold must be between 0 and 100."
  }
}

variable "stop_condition_instance_id" {
  description = "Instance ID for stop condition alarm"
  type        = string
  default     = ""
}


variable "create_service_linked_role" {
  description = "Create service-linked role for FIS (set to false if already exists)"
  type        = bool
  default     = true
}

# =============================================================================
# NETWORK CONFIGURATION
# =============================================================================

variable "vpc_id" {
  description = "VPC ID for network-related actions"
  type        = string
  default     = ""
}

variable "allowed_cidrs" {
  description = "CIDR blocks allowed to trigger experiments"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}



# These are the missing variables causing your error
variable "skip_data_sources" {
  description = "Skip data source lookups and use provided resource IDs"
  type        = bool
  default     = false
}

variable "target_subnet_ids" {
  description = "List of subnet IDs to target (used when skip_data_sources is true)"
  type        = list(string)
  default     = []
}

# =============================================================================
# ENVIRONMENT-SPECIFIC OVERRIDES
# =============================================================================

variable "environment_config" {
  description = "Environment-specific configuration overrides"
  type = map(object({
    max_duration_minutes    = number
    max_target_instances   = number
    allow_termination      = bool
    require_approval       = bool
    enable_notifications   = bool
  }))
  default = {
    dev = {
      max_duration_minutes  = 60
      max_target_instances = 10
      allow_termination    = true
      require_approval     = false
      enable_notifications = false
    }
    staging = {
      max_duration_minutes  = 30
      max_target_instances = 5
      allow_termination    = false
      require_approval     = true
      enable_notifications = true
    }
    prod = {
      max_duration_minutes  = 15
      max_target_instances = 2
      allow_termination    = false
      require_approval     = true
      enable_notifications = true
    }
  }
}


