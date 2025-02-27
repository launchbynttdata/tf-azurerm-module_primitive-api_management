# For certification_configuration, the `ca.cer` must be present in the same directory as the main.tf file

product_family       = "dso"
product_service      = "apim411"
region               = "eastus"
sku_name             = "Developer_1"
publisher_name       = "Launch DSO"
publisher_email      = "example@nttdata.com"
virtual_network_type = "Internal"

# While creation, this must be true
public_network_access_enabled = true

additional_vnet_links = {}
