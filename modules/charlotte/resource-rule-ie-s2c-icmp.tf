# Terraform V2
resource "sgroups_cidr_icmp_rules" "rules" {
  depends_on = [
    sgroups_groups.groups,
  ]
  items = {
    for key, value in local.rules_map_all_ie_s2c_by_proto_map :
      "icmp${split("icmpIPv", value.transport).1}:cidr(${value.cidr})sg(${value.sg_name})${value.traffic}" => {

        logs        = value.access.logs
        trace       = value.access.trace

        traffic     = value.traffic

        sg_name     = value.sg_name
        cidr        = value.cidr

        ip_v        = split("icmp", value.transport).1
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
