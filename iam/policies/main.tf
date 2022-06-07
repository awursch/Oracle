terraform {
  required_providers {
    oci = {
      source                = "oracle/oci"
      configuration_aliases = [oci]
    }
  }
}

locals {
  security_admins_policy_list = concat(
    var.key_id != "PLACEHOLDER" ? [
      # Ability to associate an Object Storage bucket, Block Volume volume, File Storage file system, Kubernetes cluster, or Streaming stream pool with a specific key
      "Allow group ${var.security_admins_group_name} to use key-delegate in compartment ${var.security_compartment_name} where target.key.id = '${var.key_id}'",
    ] : [],
    var.vault_id != "PLACEHOLDER" ? [
      # Ability to do all things with secrets in a specific vault
      "Allow group ${var.security_admins_group_name} to read vaults in compartment ${var.security_compartment_name} where target.vault.id='${var.vault_id}'",
      "Allow group ${var.security_admins_group_name} to manage secret-family in compartment ${var.security_compartment_name} where target.vault.id='${var.vault_id}'"
    ] : [],
    [
      # Ability to list, view, and perform cryptographic operations with all keys in compartment
      "Allow group ${var.security_admins_group_name} to use keys in compartment ${var.security_compartment_name}",
      "Allow service blockstorage, objectstorage-${var.region}, FssOc1Prod, oke, streaming to use keys in compartment ${var.security_compartment_name}",
    ]
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM Policy Network Admins
# ---------------------------------------------------------------------------------------------------------------------
resource "oci_identity_policy" "network_admin_policies" {
  compartment_id = var.network_compartment_id
  description    = "OCI Landing Zone VCN Administrator Policy"
  name           = var.network_admin_policy_name

  freeform_tags = {
    "Description" = "Policy for access to all network resources in Network Compartment",
    "CostCenter"  = var.tag_cost_center,
    "GeoLocation" = var.tag_geo_location
  }

  statements = [
    "Allow group ${var.network_admin_group_name} to manage virtual-network-family in compartment ${var.network_compartment_name}",
    # Ability to manage all resources in the Bastion service in all compartments
    "Allow group ${var.network_admin_group_name} to manage bastion in compartment ${var.network_compartment_name}",
    "Allow group ${var.network_admin_group_name} to manage bastion-session in compartment ${var.network_compartment_name}",
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM Policies LB Users
# ---------------------------------------------------------------------------------------------------------------------
# resource "oci_identity_policy" "lb_users_policies" {
#   for_each       = toset(var.workload_compartment_name_list)
#   compartment_id = var.network_compartment_id
#   description    = "OCI Landing Zone Load Balancer User Policy"
#   name           = "OCI-LZ-${each.value}-LB-User-Policy"

#   freeform_tags = {
#     "Description" = "Policy for access to all components in Load-balancing and use network family in Network compartment",
#     "CostCenter"  = var.tag_cost_center,
#     "GeoLocation" = var.tag_geo_location
#   }

#   statements = [
#     "Allow group ${var.lb_users_group_name} to use virtual-network-family in compartment ${var.network_compartment_name}",
#     "Allow group ${var.lb_users_group_name} to manage load-balancers in compartment ${var.network_compartment_name}"
#   ]
# }

# ---------------------------------------------------------------------------------------------------------------------
# IAM Policies Security Admins
# ---------------------------------------------------------------------------------------------------------------------
resource "oci_identity_policy" "security_admins_policy" {
  compartment_id = var.security_compartment_id
  description    = "OCI Landing Zone Security Admin Policy"
  name           = var.security_admins_policy_name

  freeform_tags = {
    "Description" = "Policy for Security Admin Users",
    "CostCenter"  = var.tag_cost_center,
    "GeoLocation" = var.tag_geo_location
  }

  statements = local.security_admins_policy_list
}

resource "oci_identity_policy" "security_admins_policy_network" {
  compartment_id = var.network_compartment_id
  description    = "OCI Landing Zone Security Admin Network Policy"
  name           = "${var.security_admins_policy_name}-Network"

  freeform_tags = {
    "Description" = "Network Policy for Security Admin Users",
    "CostCenter"  = var.tag_cost_center,
    "GeoLocation" = var.tag_geo_location
  }

  statements = [
    "Allow group ${var.security_admins_group_name} to manage virtual-network-family in compartment ${var.network_compartment_name}",
  ]
}

resource "oci_identity_policy" "security_admins_policy_compute" {
  compartment_id = var.tenancy_ocid
  description    = "OCI Landing Zone Security Admin Compute Policy"
  name           = "${var.security_admins_policy_name}-Compute${var.suffix}"

  freeform_tags = {
    "Description" = "Compute Policy for Security Admin Users",
    "CostCenter"  = var.tag_cost_center,
    "GeoLocation" = var.tag_geo_location
  }

  statements = [
    "Allow group ${var.security_admins_group_name} to read instance-family in tenancy",
    "Allow group ${var.security_admins_group_name} to read instance-agent-plugins in tenancy",
    "Allow group ${var.security_admins_group_name} to inspect work-requests in tenancy"
  ]
}
# ---------------------------------------------------------------------------------------------------------------------
# IAM Policy Cloud Guard Operator
# ---------------------------------------------------------------------------------------------------------------------
resource "oci_identity_policy" "cloud_guard_operators_policies" {
  compartment_id = var.tenancy_ocid
  description    = "OCI Landing Zone Cloud Guard Operators Policy"
  name           = "${var.cloud_guard_operators_policy_name}${var.suffix}"

  freeform_tags = {
    "Description" = "Policy for Cloud Guard Operators",
    "CostCenter"  = var.tag_cost_center,
    "GeoLocation" = var.tag_geo_location
  }

  statements = [
    # Basic access to Cloud Guard - read announcements
    "Allow group ${var.cloud_guard_operators_group_name} to read cloud-guard-config in tenancy",
    "Allow group ${var.cloud_guard_operators_group_name} to read announcements in tenancy",
    # Read access to Risk and Security Scores
    "Allow group ${var.cloud_guard_operators_group_name} to inspect cloud-guard-risk-scores in tenancy",
    "Allow group ${var.cloud_guard_operators_group_name} to inspect cloud-guard-security-scores in tenancy",
    # Read-only access to Cloud Guard problems
    "Allow group ${var.cloud_guard_operators_group_name} to read cloud-guard-family in tenancy",
    "Allow group ${var.cloud_guard_operators_group_name} to inspect cloud-guard-detectors in tenancy",
    "Allow group ${var.cloud_guard_operators_group_name} to inspect cloud-guard-targets in tenancy",
    "Allow group ${var.cloud_guard_operators_group_name} to inspect cloud-guard-resource-types in tenancy",
    "Allow group ${var.cloud_guard_operators_group_name} to read compartments in tenancy",
    # Read-only access to Cloud Guard detector recipes
    "Allow group ${var.cloud_guard_operators_group_name} to read cloud-guard-detector-recipes in tenancy"
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM Policies Cloud Guard Analyst
# ---------------------------------------------------------------------------------------------------------------------
resource "oci_identity_policy" "cloud_guard_analysts_policy" {
  compartment_id = var.tenancy_ocid
  description    = "OCI Landing Zone Cloud Guard Analyst Policy"
  name           = "${var.cloud_guard_analysts_policy_name}${var.suffix}"

  freeform_tags = {
    "Description" = "Policy for Cloud Guard Analyst Users",
    "CostCenter"  = var.tag_cost_center,
    "GeoLocation" = var.tag_geo_location
  }

  statements = [
    # Basic access to Cloud Guard - read announcements
    "Allow group ${var.cloud_guard_analysts_group_name} to read cloud-guard-config in tenancy",
    "Allow group ${var.cloud_guard_analysts_group_name} to read announcements in tenancy",
    # Read access to Risk and Security Scores
    "Allow group ${var.cloud_guard_analysts_group_name} to inspect cloud-guard-risk-scores in tenancy",
    "Allow group ${var.cloud_guard_analysts_group_name} to inspect cloud-guard-security-scores in tenancy",
    # Read-only access to Cloud Guard problems
    "Allow group ${var.cloud_guard_analysts_group_name} to read cloud-guard-family in tenancy",
    "Allow group ${var.cloud_guard_analysts_group_name} to inspect cloud-guard-detectors in tenancy",
    "Allow group ${var.cloud_guard_analysts_group_name} to inspect cloud-guard-resource-types in tenancy",
    "Allow group ${var.cloud_guard_analysts_group_name} to read compartments in tenancy",
    # Read-only access to Cloud Guard detector recipes
    "Allow group ${var.cloud_guard_analysts_group_name} to read cloud-guard-detector-recipes in tenancy",

    # Read Problems and Recommendations
    "Allow group ${var.cloud_guard_analysts_group_name} to inspect cloud-guard-problems in tenancy",
    "Allow group ${var.cloud_guard_analysts_group_name} to inspect cloud-guard-recommendations in tenancy",
    # Execute Responder
    "Allow group ${var.cloud_guard_analysts_group_name} to read cloud-guard-responder-recipes in tenancy",
    "Allow group ${var.cloud_guard_analysts_group_name} to use cloud-guard-responder-executions in tenancy",
    # Create and update cloud guard targets
    "Allow group ${var.cloud_guard_analysts_group_name} to manage cloud-guard-targets in tenancy",
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM Policy Cloud Guard Architect
# ---------------------------------------------------------------------------------------------------------------------
resource "oci_identity_policy" "cloud_guard_architects_policies" {
  compartment_id = var.tenancy_ocid
  description    = "OCI Landing Zone Cloud Guard Architect Policy"
  name           = "${var.cloud_guard_architects_policy_name}${var.suffix}"

  freeform_tags = {
    "Description" = "Policy for Cloud Guard Architect",
    "CostCenter"  = var.tag_cost_center,
    "GeoLocation" = var.tag_geo_location
  }

  statements = [
    # Admin access to Cloud Guard
    "Allow group ${var.cloud_guard_architects_group_name} to manage cloud-guard-family in tenancy"
  ]
}