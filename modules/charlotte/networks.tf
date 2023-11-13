# Terraform V1
# resource "sgroups_networks" "networks" {

#   dynamic "items" {
#     for_each = local.networks_map

#     content {
#       name    = items.key
#       cidr    = items.value
#     }
#   }
# }

# Terraform V2
resource "sgroups_networks" "networks" {
  items = {
    for key, value in local.networks_map :
      key => {
        name = key
        cidr = value
      }
  }
}
