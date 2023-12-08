locals {

    # Получаем  акутальный список правил с разбивкой по ingress/egress для fromCIDRs, toCIDRs
    rules_map_all_ie_s2c = { for value in local.rules_flatten_all :
        "${value.traffic}:${value.sgroup_from}:${substr(sha256(join(",",flatten(value.CIDRSet))), 0, 8)}" => {
            sgroup_from      = value.sgroup_from
            CIDRSet          = value.CIDRSet
            access           = value.access
            logs             = try(value.logs,  false)
            trace            = try(value.trace, false)
            traffic          = value.traffic
        }
        # Условие срабатывания если есть блок CIDRSet
        if try(value.CIDRSet, ["false"]) != ["false"]
    }


    # [
    #   + {
    #       + "namespace/env/gitlab-runner:11.0.0.0/8:ingress:f95db275" = {
    #           + access  = {
    #               + tcp = [
    #                   + {
    #                       + description = ""
    #                       + ports_to    = [
    #                           + 123,
    #                         ]
    #                     },
    #                 ]
    #               + udp = [
    #                   + {
    #                       + description = ""
    #                       + ports_to    = [
    #                           + 123,
    #                         ]
    #                     },
    #                 ]
    #             }
    #           + cidr    = "11.0.0.0/8"
    #           + logs    = false
    #           + sg_name = "namespace/env/gitlab-runner"
    #           + trace   = false
    #           + traffic = "ingress"
    #         }
    #     },
    # ]
    # --->
    # Получаем  акутальный список правил с разбивкой по ingress/egress для каждого CIDR
    rules_map_all_ie_s2c_flatten = flatten([
        for key, value in local.rules_map_all_ie_s2c: [
            for cidr in value.CIDRSet: {
                 "${value.sgroup_from}:${cidr}:${value.traffic}:${split(":", key)[1]}" = {
                    sg_name     = value.sgroup_from
                    cidr        = cidr
                    access      = value.access
                    logs        = value.logs
                    trace       = value.trace
                    traffic     = value.traffic
                }
            }
        ]
    ])

    rules_map_all_ie_s2c_map = { for item in local.rules_map_all_ie_s2c_flatten :
      keys(item)[0] => values(item)[0]
    }

    # [   {
    #       + "udp:namespace/env/gitlab-runner:11.0.0.0/8:ingress:f95db275" = {
    #           + access  = [
    #               + {
    #                   + description = ""
    #                   + ports_to    = [
    #                       + 123,
    #                     ]
    #                 },
    #             ]
    #           + cidr    = "11.0.0.0/8"
    #           + logs    = false
    #           + proto   = "udp"
    #           + sg_name = "namespace/env/gitlab-runner"
    #           + trace   = false
    #           + traffic = "ingress"
    #         }
    #     },
    # ]
    #---->
    # Получаем  акутальный список правил с разбивкой по PROTO для каждого CIDR
    rules_map_all_ie_s2c_by_proto_flatten = flatten([
        for key, value in local.rules_map_all_ie_s2c_map: [
                for proto, access in value.access: {
                "${proto}:${key}": {
                    proto           = proto
                    sg_name         = value.sg_name
                    cidr            = value.cidr
                    access          = value.access[proto]
                    logs            = value.logs
                    trace           = value.trace
                    traffic         = value.traffic
                }
            }
        ]
    ])

    rules_map_all_ie_s2c_by_proto_map = { for item in local.rules_map_all_ie_s2c_by_proto_flatten :
      keys(item)[0] => values(item)[0]
    }
}
