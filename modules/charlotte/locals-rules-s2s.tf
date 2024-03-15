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


    # {
    #   + "namespace/env/gitlab-runner:71439deb:s2s" = {
    #       + access      = {
    #           + tcp = [
    #               + {
    #                   + description = ""
    #                   + ports_to    = [
    #                       + 6443,
    #                     ]
    #                 },
    #             ]
    #         }
    #       + logs        = false
    #       + sgroupSet   = [
    #           + "k8s/prod/k8s.ads-dl.control-plane",
    #           + "k8s/prod/k8s.ads-el.control-plane",
    #         ]
    #       + sgroup_from = "namespace/env/gitlab-runner"
    #       + trace       = false
    #       + traffic     = "s2s"
    #     }
    # }
    # ->
    # CLASSIC LIST SGROUPs RESOURCEs
    rules_sgroup_set_all = { for item in local.rules_flatten_all :
        "${item.sgroup_from}:${substr(sha256(join(",",flatten(item.sgroupSet))), 0, 8)}:${item.traffic}" => {
            sgroup_from      = item.sgroup_from
            sgroup_set       = item.sgroupSet
            access           = item.access
            # logs             = try(item.logs,  false)
            # trace            = try(item.trace, false)
            traffic          = item.traffic
        }
        # Условие срабатывания если есть блок sgroupSet
        if try(item.sgroupSet, []) != []
    }

    # 
    #   + {
    #       + "namespace/env/gitlab-runner:k8s/dev/k8s.devel-dl.services:s2s:dbc131db" = {
    #           + access      = {
    #               + tcp = [
    #                   + {
    #                       + description = "Access to ingress"
    #                       + ports_to    = [
    #                           + 80,
    #                           + 443,
    #                         ]
    #                     },
    #                 ]
    #             }
    #           + logs        = false
    #           + sgroup_from = "namespace/env/gitlab-runner"
    #           + sgroup_to   = "k8s/dev/k8s.devel-dl.services"
    #           + trace       = false
    #           + traffic     = "s2s"
    #         }
    #     }
    # 
    # ->
    # CLASSIC LIST SGROUPs RESOURCEs -> # CLASSIC SINGLE SGROUP RESOURCE
    rules_sgoup_to_flatten_all = flatten([
        for key, value in local.rules_sgroup_set_all: [
            for sgroup in value.sgroup_set: {
                 "${value.sgroup_from}:${sgroup}:${value.traffic}:${split(":", key)[1]}" = {
                    sgroup_from = value.sgroup_from
                    sgroup_to   = sgroup
                    access      = value.access
                    # logs        = try(value.logs, false)
                    # trace       = try(value.logs, false)
                    traffic     = value.traffic
                }
            }
        ]
    ])

    rules_sgoup_to_map_all = { for item in local.rules_sgoup_to_flatten_all :
      keys(item)[0] => values(item)[0]
    }


    #  [
    #   + {
    #       + "udp:no-routed:namespace/env/gitlab-runner:s2s" = {
    #           + access      = [
    #               + {
    #                   + description = ""
    #                   + ports_to    = [
    #                       + 53,
    #                     ]
    #                 },
    #             ]
    #           + logs        = false
    #           + transport       = "udp"
    #           + sgroup_from = "no-routed"
    #           + sgroup_to   = "namespace/env/gitlab-runner"
    #           + trace       = false
    #           + traffic     = "s2s"
    #         }
    #     }
    #  ]
    # ->
    rules_sgroups_by_proto_flatten_all = flatten([
        for key, value in local.rules_sgoup_to_map_all: [
                for transport, access in value.access: {
                "${transport}:${key}": {
                    transport       = transport
                    sgroup_from     = value.sgroup_from
                    sgroup_to       = value.sgroup_to
                    access          = value.access[transport]
                    logs            = try(value.access[transport].logs,  false)
                    trace           = try(value.access[transport].trace, false)
                    traffic         = value.traffic
                }
            }
        ]
    ])

    rules_sgroup_set_new_map_all = { for item in local.rules_sgroups_by_proto_flatten_all :
      keys(item)[0] => values(item)[0]
    }

}
