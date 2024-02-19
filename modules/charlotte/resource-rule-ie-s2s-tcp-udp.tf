# Terraform V2
resource "sgroups_ie_rules" "rules" {
  depends_on = [
    sgroups_groups.groups,
  ]
  items = {
    for key, value in local.rules_map_all_ie_s2s_by_proto_map :
      "${value.transport}:sg_local(${value.sg_local})sg(${value.sg})${value.traffic}" => {
        
        traffic     = value.traffic

        sg          = value.sg
        sg_local    = value.sg_local

        transport   = value.transport
        logs        = value.logs
        trace       = value.trace

        ports = flatten([
          for port in value.access: {
            s = try(join(",", port.ports_from), null)
            d = try(join(",", port.ports_to),   null)
          }
        ])
      }

      if contains(["tcp:ingress",
                   "udp:ingress",
                   "tcp:egress",
                   "udp:egress"], "${value.transport}:${value.traffic}")
  }
}
