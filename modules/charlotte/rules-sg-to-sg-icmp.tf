# Terraform V2
resource "sgroups_icmp_rules" "rulesIPv4" {
  depends_on = [
    sgroups_groups.groups,
  ]
  items = {
    for key, value in local.rules_sgoups_to_new_map :
      "sg(${value.sgroup_from})sg(${value.sgroup_to})icmp4" => {
        
        logs    = value.logs
        trace   = value.trace
        sg_from = value.sgroup_from
        sg_to   = value.sgroup_to
        ip_v    = split("icmp", value.proto).1

        type = flatten([
          for item in value.access: [item.type]
        ])
      }
    if contains(["icmpIPv4"], value.proto)
  }
}

resource "sgroups_icmp_rules" "rulesIPv6" {
  depends_on = [
    sgroups_groups.groups,
  ]
  items = {
    for key, value in local.rules_sgoups_to_new_map :
      "sg(${value.sgroup_from})sg(${value.sgroup_to})icmp6" => {
        
        logs    = value.logs
        trace   = value.trace
        sg_from = value.sgroup_from
        sg_to   = value.sgroup_to
        ip_v    = split("icmp", value.proto).1

        type = flatten([
          for item in value.access: [item.type]
        ])
      }
    if contains(["icmpIPv6"], value.proto)
  }
}
