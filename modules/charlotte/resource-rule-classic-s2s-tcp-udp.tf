# Terraform V2
resource "sgroups_rules" "rules" {
  depends_on = [
    sgroups_groups.groups,
  ]
  items = {
    for key, value in local.rules_sgroup_set_new_map_all :
      "${value.transport}:sg(${value.sgroup_from})sg(${value.sgroup_to})" => {
        
        transport   = value.transport
        logs        = value.logs
        # trace   = value.trace #TODO
        sg_from     = value.sgroup_from
        sg_to       = value.sgroup_to

        ports = flatten([
          for port in value.access.ports: {
            s = try(join(",", port.ports_from), null)
            d = try(join(",", port.ports_to),   null)
          }
        ])
      }
      if contains(["tcp:s2s", "udp:s2s"], "${value.transport}:${value.traffic}")
  }
}
