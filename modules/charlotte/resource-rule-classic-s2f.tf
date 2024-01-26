# Terraform V2
resource "sgroups_fqdn_rules" "rules" {
  depends_on = [
    sgroups_groups.groups,
  ]
  items = {
    for key, value in local.rules_fqdn_to_map :
      "${value.transport}:sg(${value.sgroup_from})fqdn(${value.fqdn_to})" => {
        transport = value.transport
        logs      = value.logs
        trace     = value.trace
        sg_from   = value.sgroup_from
        fqdn      = value.fqdn_to
        protocols = value.protocols
        ports = flatten([
          for port in value.access: {
            s = try(join(",", port.ports_from), null)
            d = try(join(",", port.ports_to),   null)
          }
        ])
      }
  }
}
