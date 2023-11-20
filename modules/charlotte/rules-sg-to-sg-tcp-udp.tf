# Terraform V2
resource "sgroups_rules" "rules" {
  depends_on = [
    sgroups_groups.groups,
  ]
  items = {
    for key, value in local.rules_sgoups_to_new_map :
      "${value.proto}:sg(${value.sgroup_from}):sg(${value.sgroup_to})" => {
        
        proto   = value.proto
        logs    = value.logs
        sg_from = value.sgroup_from
        sg_to   = value.sgroup_to

        ports = flatten([
          for port in value.access: {
            s = try(join(",", port.ports_from), null)
            d = try(join(",", port.ports_to),   null)
          }
        ])
      }
      if contains(["tcp", "udp"], value.proto)
  }
}
