locals {
    default_action_global = "ACCEPT"
    security_groups = flatten([
        for sg, value in var.sgroups_var : [
            value
        ]
    ])

    security_groups_network__name__flatten = flatten([
        for security_group in local.security_groups : {
            "${security_group.name}": {

                cidrs = flatten([
                    for cidr in try(security_group.cidrs, []):
                        cidr
                 ])

                default_action  = try(security_group.default_rules.access.default.action, local.default_action_global)
                logs            = try(security_group.default_rules.access.default.logs,   false)
                trace           = try(security_group.default_rules.access.default.trace,  false)

                icmp = try(security_group.default_rules.access.icmp.type, null) == null ? null : {
                    logs  = try(security_group.default_rules.access.icmp.logs,   false)
                    trace = try(security_group.default_rules.access.icmp.trace,  false)
                    type  = try(security_group.default_rules.access.icmp.type,   [])
                }
                icmp6 = try(security_group.default_rules.access.icmp6.type, null) == null ? null : {
                    logs  = try(security_group.default_rules.access.icmp6.logs,   false)
                    trace = try(security_group.default_rules.access.icmp6.trace,  false)
                    type  = try(security_group.default_rules.access.icmp6.type,   [])
                }


            }
        }
    ])

    # Конвертация flatten в map
    security_groups_network__name__map = { for item in local.security_groups_network__name__flatten :
        keys(item)[0] => values(item)[0]
        # Удаляет SG если в ней нету Networks
        # Нужна, что бы можно было сначала создать SG и Networks потом добавить правила иначе будет перезапись в 0 
        if values(item)[0] != ""
    }

}