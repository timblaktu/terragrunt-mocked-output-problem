data "aws_region" "current" {}
data "aws_availability_zones" "available" {}
# Password for ArgoCD Admin in Management Cluster
# For now, we create an identical, static secret in each region.
# TODO: resolve how to better manage ArgoCD admin password
resource "random_password" "argocd_admin_shared" {
    length           = 16
    special          = true
    override_special = "!#$%&*()-_=+[]{}<>:?"
}
output "name" {
  value = data.aws_region.current.name
  description = "Name of current region"
}
output "availability_zone_names" {
  value = data.aws_availability_zones.available.names
  description = "List of the Availability Zone names available by this account in the currently active region"
}
output "argocd_admin_shared_password" {
  value = random_password.argocd_admin_shared
  sensitive = true
  description = "Random password generated once per region to be used as admin password for all argocd deployments in that region"
}
