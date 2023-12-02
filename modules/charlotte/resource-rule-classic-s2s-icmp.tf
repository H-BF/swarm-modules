# Terraform V2
resource "sgroups_icmp_rules" "rules" {
  depends_on = [
    sgroups_groups.groups,
  ]
  items = {
    for key, value in local.rules_sgroups_to_new_map_all :
      "sg(${value.sgroup_from})sg(${value.sgroup_to})icmp${split("icmpIPv", value.proto).1}" => {
        
        logs    = value.logs
        trace   = value.trace
        sg_from = value.sgroup_from
        sg_to   = value.sgroup_to
        ip_v    = split("icmp", value.proto).1

        type = flatten([
          for item in value.access: [item.type]
        ])
      }
    if contains(["icmpIPv6:s2s", "icmpIPv4:s2s"], "${value.proto}:${value.traffic}")
  }
}
