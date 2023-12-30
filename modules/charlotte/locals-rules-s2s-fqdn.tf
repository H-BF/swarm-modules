locals {

    rules_sg_to_fqdn_map_egress = { for item in local.rules_flatten_all :
        "${item.sgroup_from}:${substr(sha256(join(",",flatten(item.fqdnSet))), 0, 8)}" => {
            access      = item.access
            sgroup_from = item.sgroup_from
            fqdnSet     = try(item.fqdnSet, [])
            logs        = try(item.logs,  false)
            trace       = try(item.trace, false)
            traffic     = item.traffic
        }
        # Условие срабатывания если есть блок fqdns
        if try(item.fqdnSet, []) != []
    }

    rules_sg_to_fqdn_map_egress_validating = { for key, value in local.rules_sg_to_fqdn_map_egress :
        key => value
        if contains(["egress"], "${value.traffic}")
    }

    rules_fqdn_to_flatten = flatten([
        for key, value in local.rules_sg_to_fqdn_map_egress_validating: [
            for fqdn in value.fqdnSet: [
                for proto, access in value.access: {
                "${key}:${fqdn}:${proto}": {
                    fqdn_to         = fqdn
                    proto           = proto
                    sgroup_from     = value.sgroup_from
                    access          = value.access[proto]
                    logs            = try(value.logs,  false)
                    trace           = try(value.trace, false)
                }
            }
            ]
        ]
    ])

    rules_fqdn_to_map = { for item in local.rules_fqdn_to_flatten :
      keys(item)[0] => values(item)[0]
    }
    

}
