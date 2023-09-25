resource "sgroups_networks" "networks" {

  dynamic "items" {
    for_each = local.networks_map

    content {
      name    = items.key
      cidr    = items.value
    }
  }

}

resource "sgroups_groups" "groups" {
  depends_on = [
    sgroups_networks.networks
  ]

  dynamic "items" {
    for_each = local.security_groups_network__name__map

    content {
      name            = items.key
      networks        = items.value.cidr
      logs            = items.value.logs
      trace           = items.value.trace
      default_action  = items.value.default_action
    }
  }
}
