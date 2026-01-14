# Terraform Configuration for AWS FIS Self-Service Solution
# This configuration creates AWS Fault Injection Simulator resources
# with Jenkins automation support for chaos engineering

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.6.0"
    }
  }
}
# Configure the AWS Provider
provider "aws" {
  region = "ap-east-1"

  default_tags {
    tags = {
      Project             = "AWS-FIS-Experiment"
      Environment         = "dev"
      ManagedBy           = "Terraform"
      # Team              = var.team_name
      #CostCenter         = var.cost_center
      # CreatedDate       = formatdate("YYYY-MM-DD", timestamp())
    }
  }
}

# Data sources for current AWS account and caller identity
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Create IAM Service Linked Role for FIS (if it doesn't exist)
#resource "aws_iam_service_linked_role" "fis" {
# count            = var.create_service_linked_role ? 1 : 0
# aws_service_name = "fis.amazonaws.com"
# description      = "Service-linked role for AWS Fault Injection Simulator"
#}

# Create IAM role for FIS experiments
#resource "aws_iam_role" "fis_experiment_role" {
#  name = "${var.project_name}-fis-experiment-role"

# assume_role_policy = jsonencode({
#   Version = "2012-10-17"
#   Statement = [
#     {
#       Action = "sts:AssumeRole"
#       Effect = "Allow"
#       Principal = {
#         Service = "fis.amazonaws.com"
#       }
#       Condition = {
#         StringEquals = {
#           "aws:SourceAccount" = data.aws_caller_identity.current.account_id
#         }
#       }
#     }
#   ]
# })
#}

data "aws_iam_role" "existing_fis_role" {
  name = "iam-role-fis-nonprod"

}

# Comprehensive IAM policy for FIS experiment role
resource "aws_iam_role_policy" "fis_experiment_policy" {
  # name = "${var.project_name}-fis-experiment-policy"
    name = "AwsSSOInlinePolicy"
  role = data.aws_iam_role.existing_fis_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # EC2 Permissions for instance operations
      {
        Sid    = "EC2Permissions"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeSnapshots",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumeStatus",
          "ec2:DescribeVolumeAttribute",
          "ec2:DescribeSubnets",
          "ec2:DescribeNetworkAcls",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeImages",
          "ec2:TerminateInstances",
          "ec2:StopInstances",
          "ec2:StartInstances",
          "ec2:RebootInstances",
          "ec2:CreateTags",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      },
      # Auto Scaling Group Permissions
      {
        Sid    = "AutoScalingPermissions"
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:UpdateAutoScalingGroup"
        ]
        Resource = "*"
      },
      # Network ACL Permissions for network disruption
      {
        Sid    = "NetworkACLPermissions"
		Effect = "Allow"
        Action = [
          "ec2:CreateNetworkAcl",
          "ec2:CreateNetworkAclEntry",
          "ec2:DeleteNetworkAcl",
          "ec2:DeleteNetworkAclEntry",
          "ec2:ReplaceNetworkAclAssociation",
          "ec2:AssociateNetworkAcl",
          "ec2:DisassociateNetworkAcl",
          "ec2:ReplaceNetworkAclEntry"
        ]
        Resource = "*"
      },
      # IAM Permissions for role-based actions
      {
        Sid    = "IAMPermissions"
        Effect = "Allow"
        Action = [
          "iam:ListRoles",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:ListInstanceProfiles",
          "iam:PassRole"
        ]
        Resource = "*"
      },
      # SSM Permissions for EC2 instance commands
      {
        Sid    = "SSMPermissions"
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:ListCommands",
          "ssm:ListCommandInvocations",
          "ssm:DescribeInstanceInformation",
          "ssm:GetCommandInvocation",
          "ssm:CancelCommand"
        ]
        Resource = "*"
      },
      # FIS Experiment Template
      {
            "Effect": "Allow",
            "Action": [
                "fis:CreateExperimentTemplate",
                "fis:TagResource"
            ],
			"Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:PassRole"
            ],
            "Resource": "arn:aws:iam::333347968576:role/service-role/fis-experiment-role*"
        },
      # Tag-based resource access
      {
        Sid    = "TagBasedAccess"
        Effect = "Allow"
        Action = [
          "tag:GetResources"
        ]
        Resource = "*"
      }
    ]
  })
}


locals {
  # Define subnet_ids based on your configuration approach
  subnet_ids = var.skip_data_sources ? var.target_subnet_ids : data.aws_subnets.target_subnets.ids


  # Limit to first 5 subnets to avoid AWS FIS ARN limit
  limited_subnet_ids = slice(local.subnet_ids, 0, min(5, length(local.subnet_ids)))
  limited_subnet_ids_1 = slice(local.subnet_ids,5, length(local.subnet_ids))
}


# Data sources for dynamic resource discovery
data "aws_instances" "target_instances" {
  filter {
    name   = "tag:kubernetes.io/cluster/${var.target_cluster_name}"
    values = ["owned"]
  }
  filter {
    name   = "availability-zone"
    values = [var.target_availability_zone]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
  filter {
    name = "vpc-id"
    values = [var.vpc_id] # Your actual VPC ID
  }

}

data "aws_subnets" "target_subnets" {
  filter {
    name   = "availability-zone"
    values = [var.target_availability_zone]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
  filter {
    name  = "vpc-id"
    values = [var.vpc_id]  # Your actual VPC ID
  }
}

data "aws_eks_cluster" "target" {
  name = var.target_cluster_name
}

# Create CloudWatch Alarms as stop conditions (optional)
resource "aws_cloudwatch_metric_alarm" "fis_stop_condition" {
  count = var.create_stop_condition_alarm ? 1 : 0
  alarm_name          = "${var.project_name}-fis-stop-condition"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = var.stop_condition_cpu_threshold
  alarm_description   = "Stop FIS experiment if CPU exceeds threshold"
  dimensions = {
    AutoScalingGroupName = "${var.target_cluster_name}-*"
  }
  tags = merge(var.tags, {
    Name       = "${var.experiment_name}-safeguard-${var.environment}"
    Experiment = var.experiment_name
  })
}


# Main FIS Experiment Template
resource "aws_fis_experiment_template" "chaos_experiment" {
  description = var.experiment_description
  role_arn    = data.aws_iam_role.existing_fis_role.arn

  # Stop conditions
  stop_condition {
    source = var.create_stop_condition_alarm ? "aws:cloudwatch:alarm" : "none"
    value  = var.create_stop_condition_alarm ? aws_cloudwatch_metric_alarm.fis_stop_condition[0].arn : null
 }

  # Action: Network Disruption (Disrupt Connectivity)
  dynamic "action" {
    for_each = var.enable_network_disruption ? [1] : []
    content {
      name        = "Disrupt-Network-1"
      action_id   = "aws:network:disrupt-connectivity"
      description = "Disrupt network connectivity for ${var.target_availability_zone} subnets"

      parameter {
        key   = "duration"
        value = var.network_disruption_duration
      }

      parameter {
        key   = "scope"
        value = var.network_disruption_scope
      }

      target {
        key   = "Subnets"
        value = "Subnets-Target-1"
      }
    }
  }
  # Action: Network Disruption (Disrupt Connectivity)
  dynamic "action" {
    for_each = var.enable_network_disruption ? [1] : []
    content {
      name        = "Disrupt-Network-2"
      action_id   = "aws:network:disrupt-connectivity"
      description = "Disrupt network connectivity for ${var.target_availability_zone} subnets"

      parameter {
        key   = "duration"
        value = var.network_disruption_duration
      }

      parameter {
        key   = "scope"
        value = var.network_disruption_scope
      }

      target {
        key   = "Subnets"
        value = "Subnets-Target-2"
      }
    }
  }
  
# Action: ASG Insufficient Instance Capacity Error
  dynamic "action" {
    for_each = var.enable_asg_capacity_error ? [1] : []
    content {
      name        = "Pause-ASG-Scaling"
      action_id   = "aws:ec2:asg-insufficient-instance-capacity-error"
      description = "Inject capacity errors for Auto Scaling Groups"

      parameter {
        key   = "availabilityZoneIdentifiers"
        value = var.target_availability_zone_id
      }

      parameter {
        key   = "duration"
        value = var.asg_capacity_error_duration
      }

      parameter {
        key   = "percentage"
        value = var.asg_capacity_error_percentage
      }

      target {
        key   = "AutoScalingGroups"
        value = "AutoScalingGroups-Target"
      }
    }
  }

# Action: API Insufficient Instance Capacity Error
  dynamic "action" {
    for_each = var.enable_api_capacity_error ? [1] : []
    content {
      name        = "Pause-Instance-Launches"
      action_id   = "aws:ec2:api-insufficient-instance-capacity-error"
      description = "Inject API capacity errors for EC2"

      parameter {
        key   = "availabilityZoneIdentifiers"
        value = var.target_availability_zone_id
      }

      parameter {
        key   = "duration"
        value = var.api_capacity_error_duration
      }

      parameter {
        key   = "percentage"
        value = var.api_capacity_error_percentage
      }

      target {
        key   = "Roles"
        value = "IAM-Role-Target"
      }
    }
  }
  
# Action: Terminate EC2 Instances
  dynamic "action" {
    for_each = var.enable_instance_termination ? [1] : []
    content {
      name         = "Terminate-Instances"
      action_id    = "aws:ec2:terminate-instances"
      description  = "Terminate EC2 instances"
      start_after  = var.instance_termination_delay > 0 ? ["Wait-Before-Terminate"] : null

      target {
        key   = "Instances"
        value = "Instances-Target"
      }
    }
  }
  
# Action: Failover- DB RDS Cluster
#  dynamic "action" {
#    for_each = var.enable_instance_termination ? [1] : []
#    content {
#      name         = "DB-Failover"
#      action_id    = "aws:rds:failover-db-cluster"
#      description  = "RDS Failover"
##      start_after  = var.instance_termination_delay > 0 ? ["Wait-Before-Terminate"] : null
#
#      target {
#        key   = "Name"
#        value = "DB"
#      }
#    }
#  }
#
#  dynamic "target" {
#    for_each = var.enable_instance_termination ? [1] : []
#    content {
#      name           = "DB"
#      resource_type  = "aws:rds:cluster"
#      selection_mode = var.instance_selection_mode
#      resource_tag {
#        key   = "Name"
#        value = "ciam-sat1-ape1-rdsau-sat1-aud"
#        }
#
#      filter {
#        path   = "Placement.AvailabilityZone"
#        values = [var.target_availability_zone]
#      }
#    }
#  }  



# Action: Wait (used as delay before termination)
  dynamic "action" {
    for_each = var.instance_termination_delay > 0 ? [1] : []
    content {
      name        = "Wait-Before-Terminate"
      action_id   = "aws:fis:wait"
      description = "Wait before terminating instances"

      parameter {
        key   = "duration"
        value = "PT${var.instance_termination_delay}M"
      }
    }
  }

  # Target: Auto Scaling Groups
  dynamic "target" {
    for_each = var.enable_asg_capacity_error ? [1] : []
    content {
      name           = "AutoScalingGroups-Target"
      resource_type  = "aws:ec2:autoscaling-group"
      selection_mode = var.asg_selection_mode
      
      resource_tag {
      key   = "kubernetes.io/cluster/${var.target_cluster_name}"
      value = "owned"
      }
      
      
      #dynamic "resource_tag" {
      #  for_each = var.asg_target_tags
      #  content {
      #    key   = resource_tag.key
      #    value = resource_tag.value
      #  }
      #}

      #dynamic "filter" {
      #  for_each = var.asg_target_filters
      #  content {
      #    path   = filter.value.path
      #    values = filter.value.values
      #  }
      }
    }
    
 # Target: IAM Roles
  dynamic "target" {
    for_each = var.enable_api_capacity_error ? [1] : []
    content {
      name           = "IAM-Role-Target"
      resource_type  = "aws:iam:role"
      selection_mode = var.iam_role_selection_mode
      resource_arns  = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/iam-role-fis-nonprod"]
      # dynamic "resource_arn" {
      # for_each = var.iam_role_target_arns
      # content {
      #   arn = resource_arn.value
      # }
      # }

      #dynamic "resource_tag" {
      #  for_each = var.iam_role_target_tags
      #  content {
      #    key   = resource_tag.key
      #    value = resource_tag.value
      # }
      }
    }
   

  # Target: EC2 Instances
  dynamic "target" {
    for_each = var.enable_instance_termination ? [1] : []
    content {
      name           = "Instances-Target"
      resource_type  = "aws:ec2:instance"
      selection_mode = var.instance_selection_mode
      resource_tag {
        key   = "kubernetes.io/cluster/${var.target_cluster_name}"
        value = "owned"
        }
      filter {
        path   = "State.Name"
        values = ["running"]
       }
    
      filter {
        path   = "Placement.AvailabilityZone"
        values = [var.target_availability_zone]
      }
        #dynamic "resource_tag" {
        #for_each = var.instance_target_tags
        #content {
        #  key   = resource_tag.key
        #  value = resource_tag.value
        #}
      

      #dynamic "filter" {
      #  for_each = var.instance_target_filters
      #  content {
      #    path   = filter.value.path
      #    values = filter.value.values
      #  }
      #}
    }
  } 
  

#Target: Subnets-1
#  dynamic "target" {
#    for_each = var.enable_network_disruption ? [1] : []
#    content {
#      name           = "Subnets-Target-1"
#      resource_type  = "aws:ec2:subnet"
#      selection_mode = var.subnet_selection_mode
#
#      dynamic "resource_arn" {
#        for_each = var.subnet_target_arns
#        content {
#          arn = resource_arn.value
#       }
#       }
#
#      dynamic "resource_tag" {
#        for_each = var.subnet_target_tags
#        content {
#          key   = resource_tag.key
#          value = resource_tag.value
#        }
#      }
#    }
#  }

# First 5 Subnet targets
  dynamic "target" {
   for_each = var.enable_network_disruption && length(local.limited_subnet_ids) > 0 ? [1] : []
   content {
     name           = "Subnets-Target-1"
     resource_type  = "aws:ec2:subnet"
     selection_mode = "ALL"
     #name           = "target-subnets-1"
     resource_arns = [
     for id in slice(local.limited_subnet_ids, 0, 5) :
     "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:subnet/${id}"
     ]
   } 
 }

# Second target with remaining 1 subnet
   dynamic "target" {
     for_each = var.enable_network_disruption  && length(local.limited_subnet_ids_1) > 0 ? [1] : []
     content {
       name           = "Subnets-Target-2"
       resource_type  = "aws:ec2:subnet"
       selection_mode = "ALL"
       #name           = "target-subnets-2"
       #resource_arns  = ["arn:aws:ec2:ap-east-1:333347968576:subnet/subnet-0556e58ba31c54f2e"]
       resource_arns   = [
       for id in local.limited_subnet_ids_1 : 
       "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:subnet/${id}"
     ]
     }
   }
 
# Experiment Options
   experiment_options {
     account_targeting                = var.account_targeting
     empty_target_resolution_mode     = var.empty_target_resolution_mode
     #actions_mode                     = var.actions_mode
   }

   tags = merge(var.tags, {
     Name                = "${var.project_name}-fis-experiment"
     ExperimentType      = "ChaosEngineering"
     AutomationSupported = "true"
   })
}




