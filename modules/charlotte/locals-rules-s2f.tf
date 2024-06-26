locals {

    rules_sg_to_fqdn_map_egress = { for item in local.rules_flatten_all :
        "${item.sgroup_from}:${substr(sha256(join(",",flatten(item.fqdnSet))), 0, 8)}" => {
            access      = item.access
            sgroup_from = item.sgroup_from
            protocols   = try(item.protocols, null)
            fqdnSet     = try(item.fqdnSet, [])
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
                for transport, access in value.access: {
                "${key}:${fqdn}:${transport}": {
                    fqdn_to         = fqdn
                    transport       = transport
                    protocols       = value.protocols
                    sgroup_from     = value.sgroup_from
                    access          = value.access[transport]
                    traffic         = value.traffic
                }
            }
            ]
        ]
    ])

    rules_fqdn_to_map = { for item in local.rules_fqdn_to_flatten :
      keys(item)[0] => values(item)[0]
    }
    

}
