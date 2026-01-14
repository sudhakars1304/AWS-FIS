# Outputs for AWS FIS Self-Service Terraform Solution
# These outputs provide important information for Jenkins automation and monitoring

# =============================================================================
# CORE FIS RESOURCES
# =============================================================================

output "fis_experiment_template_id" {
  description = "The ID of the FIS experiment template"
  value       = aws_fis_experiment_template.chaos_experiment.id
}

output "fis_experiment_template_arn" {
  description = "The ARN of the FIS experiment template"
  value       = "arn:aws:fis:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:experiment-template/${aws_fis_experiment_template.chaos_experiment.id}"
}

output "fis_experiment_role_arn" {
  description = "The ARN of the FIS experiment role"
  value       = data.aws_iam_role.existing_fis_role.arn
}

output "fis_experiment_role_name" {
  description = "The name of the FIS experiment role"
  value       = data.aws_iam_role.existing_fis_role.name
}

output "existing_policy_document" {
  value = aws_iam_role_policy.fis_experiment_policy.policy
}


output "enabled_actions" {
  description = "List of enabled FIS actions"
  value = {
    network_disruption      = var.enable_network_disruption
    asg_capacity_error     = var.enable_asg_capacity_error
    api_capacity_error     = var.enable_api_capacity_error
    instance_termination   = var.enable_instance_termination
  }
}

output "target_configuration" {
  description = "Target configuration summary"
  value = {
    #asg_targets = {
    #  selection_mode = var.asg_selection_mode
    #  target_tags   = var.asg_target_tags
    #  filters_count = length(var.asg_target_filters)
    #}
    # instance_targets = {
    #  selection_mode = var.instance_selection_mode
    #  target_tags   = var.instance_target_tags
    #  filters_count = length(var.instance_target_filters)
    #}
    subnet_targets = {
      selection_mode = var.subnet_selection_mode
      target_tags   = var.subnet_target_tags
      arn_count     = length(var.subnet_target_arns)
    }
    #iam_role_targets = {
    #  selection_mode = var.iam_role_selection_mode
    #  target_tags   = var.iam_role_target_tags
    #  arn_count     = length(var.iam_role_target_arns)
    #}
  }
}
