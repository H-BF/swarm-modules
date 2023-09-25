resource "sgroups_fqdn_rules" "rules" {
  depends_on = [
    sgroups_groups.groups,
  ]

  dynamic "items" {
    for_each = local.rules_fqdn_to_map

    content {
      proto   = items.value.proto
      logs    = items.value.logs
      sg_from = items.value.sgroup_from
      fqdn_to = items.value.fqdn_to

      dynamic "ports" {
        for_each = { 
          for access_item in items.value.access: 
            "${items.value.sgroup_from}:${items.value.fqdn_to}:${try(join(",", access_item.ports_from), "")}" => access_item
        }
        content {
          s = try(join(",", ports.value.ports_from), null)
          d = try(join(",", ports.value.ports_to),   null)
        }
      }
    }
  }
}


resource "sgroups_rules" "rules" {
  depends_on = [
    sgroups_groups.groups,
  ]

  dynamic "items" {
    for_each = local.rules_sgoups_to_new_map

    content {
      proto   = items.value.proto
      logs    = items.value.logs
      sg_from = items.value.sgroup_from
      sg_to   = items.value.sgroup_to

      dynamic "ports" {
        for_each = { 
          for access_item in items.value.access: 
            "${items.value.sgroup_from}:${items.value.sgroup_to}:${try(join(",", access_item.ports_from), "")}" => access_item
        }
        content {
          s = try(join(",", ports.value.ports_from), null)
          d = try(join(",", ports.value.ports_to),   null)
        }
      }
    }
  }
}
