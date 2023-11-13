# Terraform V1
# resource "sgroups_rules" "rules" {
#   depends_on = [
#     sgroups_groups.groups,
#   ]

#   dynamic "items" {
#     for_each = local.rules_sgoups_to_new_map

#     content {
#       proto   = items.value.proto
#       logs    = items.value.logs
#       sg_from = items.value.sgroup_from
#       sg_to   = items.value.sgroup_to

#       dynamic "ports" {
#         for_each = { 
#           for access_item in items.value.access: 
#             "${items.value.sgroup_from}:${items.value.sgroup_to}:${try(join(",", access_item.ports_from), "")}" => access_item
#         }
#         content {
#           s = try(join(",", ports.value.ports_from), null)
#           d = try(join(",", ports.value.ports_to),   null)
#         }
#       }
#     }
#   }
# }

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
  }
}
