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

        icmp            = value.icmp
        icmp6           = value.icmp6
      }
  }
}
