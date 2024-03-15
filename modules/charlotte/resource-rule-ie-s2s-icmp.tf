# Terraform V2
resource "sgroups_ie_icmp_rules" "rules" {
  depends_on = [
    sgroups_groups.groups,
  ]
  items = {
    for key, value in local.rules_sgroup_set_new_map_all :
      "icmp${split("icmpIPv", value.transport).1}:sg-local(${value.sgroup_from})sg(${value.sgroup_to})${value.traffic}" => {

        logs    = value.access.logs
        trace   = value.access.trace

        traffic     = value.traffic

        sg          = value.sgroup_to
        sg_local    = value.sgroup_from

        ip_v    = split("icmp", value.transport).1
        type = flatten([
          for item in value.access.types: [item.type]
        ])

        action      = try(value.access.action,   null) # Required "ACCEPT/DROP"
        priority    = try(value.access.priority, null)
      }

    if contains(["icmpIPv6:ingress",
                 "icmpIPv4:ingress",
                 "icmpIPv6:egress",
                 "icmpIPv4:egress"], "${value.transport}:${value.traffic}")
  }
}
