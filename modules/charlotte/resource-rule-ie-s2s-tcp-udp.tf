# Terraform V2
resource "sgroups_ie_rules" "rules" {
  depends_on = [
    sgroups_groups.groups,
  ]
  items = {
    for key, value in local.rules_sgroup_set_new_map_all :
      "${value.transport}:sg-local(${value.sgroup_from})sg(${value.sgroup_to})${value.traffic}" => {

        logs        = value.access.logs
        trace       = value.access.trace

        traffic     = value.traffic

        sg          = value.sgroup_to
        sg_local    = value.sgroup_from

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

      if contains(["tcp:ingress",
                   "udp:ingress",
                   "tcp:egress",
                   "udp:egress"], "${value.transport}:${value.traffic}")
  }
}
