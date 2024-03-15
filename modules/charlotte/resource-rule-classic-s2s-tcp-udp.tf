# Terraform V2
resource "sgroups_rules" "rules" {
  depends_on = [
    sgroups_groups.groups,
  ]
  items = {
    for key, value in local.rules_sgroup_set_new_map_all :
      "${value.transport}:sg(${value.sgroup_from})sg(${value.sgroup_to})" => {

        logs        = value.access.logs
        trace       = value.access.trace

        sg_from     = value.sgroup_from
        sg_to       = value.sgroup_to

        transport   = value.transport
        ports = flatten([
          for port in value.access.ports: {
            s = try(join(",", port.ports_from), null)
            d = try(join(",", port.ports_to),   null)
          }
        ])

        action      = try(value.access.action,   null) # Required "ACCEPT/DROP"
        priority    = try(value.access.priority, null)
      }
      if contains(["tcp:s2s",
                   "udp:s2s"], "${value.transport}:${value.traffic}")
  }
}
