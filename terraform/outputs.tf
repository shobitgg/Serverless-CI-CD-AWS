output "vpc_id" {
  value = module.vpc.vpc_id
}

output "this_lb_id" {
  value = module.alb.this_lb_id
}

output "this_lb_dns_name" {
  value = module.alb.this_lb_dns_name
}

output "target_group_names" {
  value = module.alb.target_group_names
}

output "ecs_service_id" {
  value = module.ecs_fargate.ecs_service_id
}

output "ecs_service_name" {
  value = module.ecs_fargate.ecs_service_name
}

output "ecs_service_cluster" {
  value = module.ecs_fargate.ecs_service_cluster
}

output "ecs_service_desired_count" {
  value = module.ecs_fargate.ecs_service_desired_count
}

output "ecs_task_definition_family" {
  value = module.ecs_fargate.ecs_task_definition_family
}

output "ecs_task_definition_revision" {
  value = module.ecs_fargate.ecs_task_definition_revision
}

output "codebuild_project_name" {
  value = module.ecs_codepipeline.codebuild_project_name
}

output "codebuild_project_id" {
  value = module.ecs_codepipeline.codebuild_project_id
}

output "codebuild_cache_bucket_name" {
  value = module.ecs_codepipeline.codebuild_cache_bucket_name
}

output "codepipeline_id" {
  value = module.ecs_codepipeline.codepipeline_id
}

output "webhook_id" {
  value = module.ecs_codepipeline.webhook_id
}

output "webhook_url" {
  value     = module.ecs_codepipeline.webhook_url
  sensitive = true
}
