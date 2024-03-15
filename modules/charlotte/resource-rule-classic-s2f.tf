# Terraform V2
resource "sgroups_fqdn_rules" "rules" {
  depends_on = [
    sgroups_groups.groups,
  ]
  items = {
    for key, value in local.rules_fqdn_to_map :
      "${value.transport}:sg(${value.sgroup_from})fqdn(${value.fqdn_to})" => {

        logs      = value.access.logs
        trace     = value.access.trace

        sg_from   = value.sgroup_from
        fqdn      = value.fqdn_to
        
        protocols = value.protocols
        transport = value.transport
        ports = flatten([
          for port in value.access.ports: {
            s = try(join(",", port.ports_from), null)
            d = try(join(",", port.ports_to),   null)
          }
        ])

        action      = try(value.access.action,   null) # Required "ACCEPT/DROP"
        priority    = try(value.access.priority, null)
      }
      if contains(["tcp:egress",
                   "udp:egress"], "${value.transport}:${value.traffic}")
  }
}
