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
