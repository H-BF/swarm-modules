locals {

    rules_sg_to_fqdn_map_s2s = { for item in local.rules_flatten_all :
        "${item.sgroup_from}:${substr(sha256(join(",",flatten(item.fqdns_to))), 0, 8)}" => {
            access      = item.access
            sgroup_from = item.sgroup_from
            fqdns_to    = try(item.fqdns_to, [])
            logs        = try(item.logs,  false)
            trace       = try(item.trace, false)
        }
        # Условие срабатывания если есть блок fqdns
        if try(item.fqdns_to, []) != []
    }

    rules_fqdn_to_flatten = flatten([
        for key, value in local.rules_sg_to_fqdn_map_s2s: [
            for fqdn in value.fqdns_to: [
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
