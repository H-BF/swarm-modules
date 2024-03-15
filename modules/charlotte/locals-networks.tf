locals {

    #### Формируем массив в котором подсети получают уникальные имена и находятся в одномерном массиве
    networks_flatten = flatten([
        for security_group in local.security_groups_network__name__flatten: [
            for key, value in security_group: [
                value.cidrs
            ]
        ]
    ])

    # Конвертация flatten в map
    networks_map = { for network in local.networks_flatten :
        keys   ({split(":",network)[0]: try(split(":",network)[1], split(":",network)[0])})[0] => 
        values ({split(":",network)[0]: try(split(":",network)[1], split(":",network)[0])})[0]
    }

}