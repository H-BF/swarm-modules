locals {

    rules_map_all_ie_s2s = { for value in local.rules_flatten_all :
        "${value.traffic}:${value.sgroup_from}:${substr(sha256(join(",",flatten(value.sgroupSet))), 0, 8)}" => {
            sgroup_from      = value.sgroup_from
            sgroup_local     = value.sgroupSet
            access           = value.access
            logs             = try(value.logs,  false)
            trace            = try(value.trace, false)
            traffic          = value.traffic
        }
        if try(value.sgroupSet, []) != []
    }

    rules_map_all_ie_s2s_validating = { for key, value in local.rules_map_all_ie_s2s :
        key => value
        if contains(["egress","ingress"], "${value.traffic}")
    }

    rules_map_all_ie_s2s_flatten = flatten([
        for key, value in local.rules_map_all_ie_s2s: [
            for sgroup in value.sgroup_local: {
                 "${value.sgroup_from}:${sgroup}:${value.traffic}:${split(":", key)[1]}" = {
                    sg          = value.sgroup_from
                    sg_local    = sgroup
                    access      = value.access
                    logs        = value.logs
                    trace       = value.trace
                    traffic     = value.traffic
                }
            }
        ]
    ])

    rules_map_all_ie_s2s_map = { for item in local.rules_map_all_ie_s2s_flatten :
      keys(item)[0] => values(item)[0]
    }

    rules_map_all_ie_s2s_by_proto_flatten = flatten([
        for key, value in local.rules_map_all_ie_s2s_map: [
                for transport, access in value.access: {
                "${transport}:${key}": {
                    transport       = transport
                    sg              = value.sg
                    sg_local        = value.sg_local
                    access          = value.access[transport]
                    logs            = value.logs
                    trace           = value.trace
                    traffic         = value.traffic
                }
            }
        ]
    ])

    rules_map_all_ie_s2s_by_proto_map = { for item in local.rules_map_all_ie_s2s_by_proto_flatten :
      keys(item)[0] => values(item)[0]
    }
}
