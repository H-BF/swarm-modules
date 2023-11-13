# Terraform V1
# resource "sgroups_groups" "groups" {
#   depends_on = [
#     sgroups_networks.networks
#   ]

#   dynamic "items" {
#     for_each = local.security_groups_network__name__map

#     content {
#       name            = items.key
#       networks        = items.value.cidr
#       logs            = items.value.logs
#       trace           = items.value.trace
#       default_action  = items.value.default_action
#     }
#   }
# }


# Terraform V2
resource "sgroups_groups" "groups" {
  depends_on = [
    sgroups_networks.networks
  ]
  items = {
    for key, value in local.security_groups_network__name__map :
      key => {
        name            = key
        networks        = value.cidr
        logs            = value.logs
        trace           = value.trace
        default_action  = value.default_action
      }
  }
}
