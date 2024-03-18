# Terraform V2
resource "sgroups_ie_icmp_rules" "rules" {
  depends_on = [
    sgroups_groups.groups,
  ]
  items = {
    for key, value in local.rules_sgroup_set_new_map_all :
      "icmp${split("icmpIPv", value.transport).1}:sg-local(${value.sgroup_from})sg(${value.sgroup_to})${value.traffic}" => {

        traffic     = value.traffic

        sg          = value.sgroup_to
        sg_local    = value.sgroup_from

        ip_v    = split("icmp", value.transport).1
        logs    = value.logs
        trace   = value.trace

        type = flatten([
          for item in value.access: [item.type]
        ])

        action      = value.action
      }

    if contains(["icmpIPv6:ingress",
                 "icmpIPv4:ingress",
                 "icmpIPv6:egress",
                 "icmpIPv4:egress"], "${value.transport}:${value.traffic}")
  }
}
