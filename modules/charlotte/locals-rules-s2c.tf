locals {

    # Получаем  акутальный список правил с разбивкой по ingress/egress для fromCIDRs, toCIDRs
    rules_map_all_ie_s2c = { for value in local.rules_flatten_all :
        "${value.traffic}:${value.sgroup_from}:${substr(sha256(join(",",flatten(value.cidrSet))), 0, 8)}" => {
            sgroup_from      = value.sgroup_from
            cidr_set         = value.cidrSet
            access           = value.access
            traffic          = value.traffic
        }
        # Условие срабатывания если есть блок cidrSet
        if try(value.cidrSet, []) != []
    }

    rules_map_all_ie_s2c_validating = { for key, value in local.rules_map_all_ie_s2c :
        key => value
        if contains(["egress","ingress"], "${value.traffic}")
    }

    # Получаем  акутальный список правил с разбивкой по ingress/egress для каждого CIDR
    rules_map_all_ie_s2c_flatten = flatten([
        for key, value in local.rules_map_all_ie_s2c: [
            for cidr in value.cidr_set: {
                 "${value.sgroup_from}:${cidr}:${value.traffic}:${split(":", key)[1]}" = {
                    sg_name     = value.sgroup_from
                    cidr        = cidr
                    access      = value.access
                    traffic     = value.traffic
                }
            }
        ]
    ])

    rules_map_all_ie_s2c_map = { for item in local.rules_map_all_ie_s2c_flatten :
      keys(item)[0] => values(item)[0]
    }

    # Получаем  акутальный список правил с разбивкой по TRANSPORT для каждого CIDR
    rules_map_all_ie_s2c_by_proto_flatten = flatten([
        for key, value in local.rules_map_all_ie_s2c_map: [
                for transport, access in value.access: {
                "${transport}:${key}": {
                    transport       = transport
                    sg_name         = value.sg_name
                    cidr            = value.cidr
                    access          = value.access[transport]
                    traffic         = value.traffic
                }
            }
        ]
    ])

    rules_map_all_ie_s2c_by_proto_map = { for item in local.rules_map_all_ie_s2c_by_proto_flatten :
      keys(item)[0] => values(item)[0]
    }
}
