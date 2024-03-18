# Terraform V2
resource "sgroups_cidr_rules" "rules" {
  depends_on = [
    sgroups_groups.groups,
  ]
  items = {
    for key, value in local.rules_map_all_ie_s2c_by_proto_map :
      "${value.transport}:cidr(${value.cidr})sg(${value.sg_name})${value.traffic}" => {
        
        traffic     = value.traffic

        sg_name     = value.sg_name
        cidr        = value.cidr

        transport   = value.transport
        logs        = value.logs
        trace       = value.trace

        ports = flatten([
          for port in value.access: {
            s = try(join(",", port.ports_from), null)
            d = try(join(",", port.ports_to),   null)
          }
        ])

        action      = value.action
      }

      if contains(["tcp:ingress",
                   "udp:ingress",
                   "tcp:egress",
                   "udp:egress"], "${value.transport}:${value.traffic}")
  }
}
