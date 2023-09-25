locals {
    security_groups = flatten([
        for sg, value in var.sgroups_var : [
            value
        ]
    ])

    #### Формируем список данных, где будет фигурировать:
    #### Имена SG, новые имена Networks и CIDR от Networks
    ##->
    #   [
    #     {
    #       "teamA_backend" = {
    #         "cidrs": = [
    #             "27ccd286ef:10.143.0.3/32",
    #         ]
    #         "default_action": "DROP"
    #         "logs":           false
    #         "trace":          false
    #       }
    #     }
    #   ]

    security_groups_network__name_cidr__flatten = flatten([
        for security_group in local.security_groups : {
            "${security_group.name}": {
                "cidrs": flatten([
                    for cidr in try(security_group.cidrs, []):
                        "${cidr}:${cidr}"
                ]),
                "default_action": try(security_group.default_action, "DROP")
                "logs":  try(security_group.logs, false)
                "trace": try(security_group.trace, false)
            }
        }
    ])

    security_group_map = { for item in local.security_groups_network__name_cidr__flatten :
        keys(item)[0] => values(item)[0]
        if item != {}
    }

    #### Формируем массив в котором подсети получают уникальные имена и находятся в одномерном массиве
    ##->
    #   [
    #     "27ccd286ef: 10.143.0.3/32",
    #     "4894792f26: 10.143.0.16/32",
    #     "53503b3b29: 193.32.219.99/32",
    #     "06ee3732a5: 176.0.0.0/8",
    #   ]

    networks_flatten = flatten([
        for security_group in local.security_groups_network__name_cidr__flatten: [
            for key, value in security_group: [
                value.cidrs
            ]
        ]
    ])

    # Конвертация flatten в map
    networks_map = { for network in local.networks_flatten :
        keys   ({split(":",network)[0]: split(":",network)[1]})[0] => 
        values ({split(":",network)[0]: split(":",network)[1]})[0]
    }

    # Формируем массив данных, где будет фигурировать sgName, cidr в виде строки
    # [
    #     {
    #       "teamA_backend"   = {
    #         "cidr": "27ccd286ef"
    #         "default_action": "DROP"
    #         "logs": false
    #         "trace": false
    #       }
    #     },
    #     {
    #       "teamA_frontend"  = {
    #         "cidr": "4894792f26"
    #         "default_action": "DROP"
    #         "logs": false
    #         "trace": false
    #       }
    #     }
    # ]
    security_groups_network__name__flatten = flatten([
        for security_group in local.security_groups : {
            "${security_group.name}": {
                "cidr":join(",",flatten([
                    for cidr in try(security_group.cidrs, []):
                        "${cidr}"
                 ]))
                "default_action": try(security_group.default_action, "ACCEPT")
                "logs":  try(security_group.logs,  false)
                "trace": try(security_group.trace, false)
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

    #### Формирует список массивов в котором, указана исходная SG и набор правил, 
    #### которые открываются по прринципу ОТ -> ДО *sgroup_from подставляется автоматически
    ##->
    # [
    #     {
    #         "teamA_backend" = [
    #                {
    #                    "access" = {
    #                        tcp = [
    #                            {
    #                                "description" = "access from teamA_backend to teamA_frontend"
    #                                "ports_to" = tolist([
    #                                    "80",
    #                                    "443",
    #                                ])
    #                            },           
    #                        ]
    #                 "logs"    = true
    #                 "sgroup_from" = "teamA_backend"
    #                 "sgroup_to"   = "teamA_frontend"
    #             }
    #         ]
    #     },
    # ]
    security_group_rules_flatten = flatten([
        for security_group in local.security_groups : {
            "${security_group.name}": flatten([
                for rule in try(security_group.rules, []):
                    merge(rule, {"sgroup_from": security_group.name})
            ])
        }
    ])

    #### Формируется список массивов с полным набором оперируемых правил
    # -> правило SG -> SGs   | SET
    # -> правило SG -> SG    | SET
    # -> правило SG -> FQDNs | SET
    #
    # [
    #     {
    #         "access" = {
    #             "tcp" = [
    #                 {
    #                 "description" = ""
    #                 "ports_to" = [
    #                     10051,
    #                 ]
    #                 },
    #             ]
    #         }
    #         "sgroup_from" = "teamA_backend"
    #         "sgroup_to" = "teamA_frontend"
    #     },
    #     {
    #         "access" = {
    #             "tcp" = [
    #                 {
    #                 "description" = ""
    #                 "ports_to" = [
    #                     6443,
    #                     ]
    #                 },
    #             ]
    #             }
    #         "logs" = true
    #         "sgroup_from" = "teamA_backend"
    #         "sgroups_to" = {
    #             "name" = "k8s-api"
    #             "sgroups" = [
    #                 "teamB_frontend",
    #                 "teamC_frontend",
    #             ]
    #             }
    #     },
    #     {
    #         "access" = {
    #             "tcp" = [
    #                 {
    #                     "description" = ""
    #                     "ports_to" = [
    #                         443,
    #                         80,
    #                     ]
    #                 },
    #             ]
    #         }
    #         "fqdns_to" = {
    #         "fqdns" = [
    #             "example.com",
    #         ]
    #         "name" = "external"
    #         }
    #         "sgroup_from" = "teamA_backend"
    #     },
    # ]
    # ->
    rules_flatten = flatten([
        for security_group in local.security_group_rules_flatten: [
            for key, value in security_group: [
                value
            ]
        ]
    ])

    #### Формируется список массивов с полным набором оперируемых правил
    # -> правило SG -> SG    | SET
    #
    # [
    #     {
    #         "access" = {
    #             "tcp" = [
    #                 {
    #                 "description" = ""
    #                 "ports_to" = [
    #                     10051,
    #                 ]
    #                 },
    #             ]
    #         }
    #         "sgroup_from" = "teamA_backend"
    #         "sgroup_to" = "teamA_frontend"
    #     },
    # ]
    # ->
    rules_map = { for item in local.rules_flatten :
        "${item.sgroup_from}:${item.sgroup_to}" => {
            sgroup_from      = item.sgroup_from
            sgroup_to       = item.sgroup_to
            access          = item.access
            logs            = try(item.logs, false)
        }
        # Условие срабатывания если есть блок sgroup_to
        if try(item.sgroup_to, "") != ""
    }

    # Конвертация flatten в map с уникальным именем по входной паре FROM_SG:TO_SG
    ######################################################
    # -> правило SG -> SGs | MAP
    # {
    #     "prod/gitlab/test/runners:k8s-services" = {
    #     "access" = {
    #        "tcp" = [
    #          {
    #            "description" = ""
    #            "ports_to" = [
    #                80,
    #                443,
    #              ]
    #          },
    #        ]
    #     }
    #     "logs" = true
    #     "sgoups_to" = [
    #         "treska/k8s/betta-el/services",
    #         "treska/k8s/analytics-el/services",
    #         "treska/k8s/cc-dl/services",
    #         "treska/k8s/portal-dl/services",
    #         "prod/k8s/prod-dl/services",
    #         "dev/k8s/devel-dl/services",
    #     ]
    #     "sgroup_from" = "prod/gitlab/test/runners"
    #   }
    # }
    # ->
    rules_sgoups_to = { for item in local.rules_flatten :
        "${item.sgroup_from}:${try(item.sgroups_to.name, "")}" => {
            sgroup_from      = item.sgroup_from
            sgoups_to       = item.sgroups_to.sgroups
            access          = item.access
            logs            = item.logs
        }
        # Условие срабатывания если есть блок sgroups_to
        if try(item.sgroups_to, []) != []
    }

    ######################################################
    # -> правило SG -> SG | SET
    # 
    # [
    #   {
    #     "715d5c6c26" = {
    #     "access" = {
    #         "tcp" = [
    #             {
    #             "description" = ""
    #             "ports_to" = [
    #                 80,
    #                 443,
    #               ]
    #             },
    #         ]
    #     }
    #     "logs" = true
    #     "sgroup_from" = "prod/gitlab/test/runners"
    #     "sgroup_to" = "dev/k8s/devel-dl/services"
    #   }
    # ]
    # ->
    rules_sgoup_to_flatten = flatten([
        for key, value in local.rules_sgoups_to: [
            for sgroup in value.sgoups_to: {
                 "${key}:${sgroup}" = {
                    sgroup_to   = sgroup
                    sgroup_from = value.sgroup_from
                    access      = value.access
                    logs        = value.logs
                }
            }
        ]
    ])

    ######################################################
    # -> правило SG -> SG | MAP
    # 
    # {
    #   {
    #     "715d5c6c26" = {
    #     "access" = {
    #         "tcp" = [
    #             {
    #             "description" = ""
    #             "ports_to" = [
    #                 80,
    #                 443,
    #               ]
    #             },
    #         ]
    #     }
    #     "logs" = true
    #     "sgroup_from" = "prod/gitlab/test/runners"
    #     "sgroup_to" = "dev/k8s/devel-dl/services"
    #   }
    # }
    # ->
    rules_sgoup_to_map = { for item in local.rules_sgoup_to_flatten :
      keys(item)[0] => values(item)[0]
    }

    rules_sgoups_to_map = merge(local.rules_map, local.rules_sgoup_to_map)

    ######################################################
    # -> правило sg -> FQDNs | MAP
    #
    # {
    #   "fc1901dbc7" = {
    #     "access" = {
    #       "tcp" = [
    #         {
    #           "description" = ""
    #           "ports_to" = [
    #             443,
    #             80,
    #           ]
    #         },
    #       ]
    #     }
    #     "fqdn_to" = [
    #       "example.com",
    #     ]
    #     "sgroup_from" = "teamA_backend"
    #   }
    # }
    #
    # ->
    rules_sg_to_fqdn_map = { for item in local.rules_flatten :
        "${item.sgroup_from}:${try(item.fqdns_to.name, "")}" => {
            access      = item.access
            sgroup_from = item.sgroup_from
            fqdns_to    = try(item.fqdns_to.fqdns, [])
            logs        = try(item.logs, false)
        }
        # Условие срабатывания если есть блок fqdns
        if try(item.fqdns_to.fqdns, []) != []
    }

    ######################################################
    # -> правило sg -> FQDN | SET
    #   [
    #     "fc1901dbc7" = {
    #     "access" = {
    #       "tcp" = [
    #         {
    #           "description" = ""
    #           "ports_to" = [
    #             443,
    #             80,
    #           ]
    #         },
    #       ]
    #     }
    #     "fqdn_to" = "nodejs.org"
    #     "logs" = true
    #     "sgroup_from" = "prod/gitlab/test/runners"
    #   ]
    # ->
    rules_fqdn_to_flatten = flatten([
        for key, value in local.rules_sg_to_fqdn_map: [
            for fqdn in value.fqdns_to: [
                for proto, access in value.access: {
                "${key}:${fqdn}:${proto}": {
                    fqdn_to         = fqdn
                    proto           = proto
                    sgroup_from     = value.sgroup_from
                    access          = value.access[proto]
                    logs            = value.logs
                }
            }
            ]
        ]
    ])

    ######################################################
    # -> правило sg -> FQDN | MAP
    #   {
    #     "fc1901dbc7" = {
    #     "access" = {
    #       "tcp" = [
    #         {
    #           "description" = ""
    #           "ports_to" = [
    #             443,
    #             80,
    #           ]
    #         },
    #       ]
    #     }
    #     "fqdn_to" = "nodejs.org"
    #     "logs" = true
    #     "sgroup_from" = "prod/gitlab/test/runners"
    #   }
    # ->
    rules_fqdn_to_map = { for item in local.rules_fqdn_to_flatten :
      keys(item)[0] => values(item)[0]
    }

    rules_sgoups_to_new_flatten = flatten([
        for key, value in local.rules_sgoups_to_map: [
                for proto, access in value.access: {
                "${key}:${proto}": {
                    proto           = proto
                    sgroup_from     = value.sgroup_from
                    sgroup_to       = value.sgroup_to
                    access          = value.access[proto]
                    logs            = value.logs
                }
            }
        ]
    ])

    rules_sgoups_to_new_map = { for item in local.rules_sgoups_to_new_flatten :
      keys(item)[0] => values(item)[0]
    }
}
