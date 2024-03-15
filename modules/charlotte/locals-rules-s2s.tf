locals {

    security_group_rules_flatten_all = flatten([
        for security_group in local.security_groups : {
            "${security_group.name}": flatten([
                for key, rules in try(security_group.rules, []): [
                    for rule in rules:
                        merge(rule, {"sgroup_from": security_group.name, "traffic": key})
                    ]
                ]
            )
        }
    ])

    rules_flatten_all = flatten([
        for security_group in local.security_group_rules_flatten_all: [
            for key, value in security_group: [
                value
            ]
        ]
    ])

    # CLASSIC LIST SGROUPs RESOURCEs
    rules_sgroup_set_all = { for item in local.rules_flatten_all :
        "${item.sgroup_from}:${substr(sha256(join(",",flatten(item.sgroupSet))), 0, 8)}:${item.traffic}" => {
            sgroup_from      = item.sgroup_from
            sgroup_set       = item.sgroupSet
            access           = item.access
            traffic          = item.traffic
        }
        # Условие срабатывания если есть блок sgroupSet
        if try(item.sgroupSet, []) != []
    }

    # CLASSIC LIST SGROUPs RESOURCEs -> # CLASSIC SINGLE SGROUP RESOURCE
    rules_sgoup_to_flatten_all = flatten([
        for key, value in local.rules_sgroup_set_all: [
            for sgroup in value.sgroup_set: {
                 "${value.sgroup_from}:${sgroup}:${value.traffic}:${split(":", key)[1]}" = {
                    sgroup_from = value.sgroup_from
                    sgroup_to   = sgroup
                    access      = value.access
                    traffic     = value.traffic
                }
            }
        ]
    ])

    rules_sgoup_to_map_all = { for item in local.rules_sgoup_to_flatten_all :
      keys(item)[0] => values(item)[0]
    }

    # Разбавка правил по протоколам
    rules_sgroups_by_proto_flatten_all = flatten([
        for key, value in local.rules_sgoup_to_map_all: [
                for transport, access in value.access: {
                "${transport}:${key}": {
                    transport       = transport
                    sgroup_from     = value.sgroup_from
                    sgroup_to       = value.sgroup_to
                    access          = value.access[transport]
                    traffic         = value.traffic
                }
            }
        ]
    ])

    rules_sgroup_set_new_map_all = { for item in local.rules_sgroups_by_proto_flatten_all :
      keys(item)[0] => values(item)[0]
    }

}
