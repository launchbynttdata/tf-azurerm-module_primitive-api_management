// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

resource "random_integer" "suffix" {
  min = 100
  max = 999
  keepers = {
    region = var.product_service
  }
}

module "resource_names" {
  source  = "terraform.registry.launch.nttdata.com/module_library/resource_name/launch"
  version = "~> 2.0"

  for_each = var.resource_names_map

  logical_product_family  = var.product_family
  logical_product_service = join("", [var.product_service, random_integer.suffix.result])
  region                  = var.region
  class_env               = var.environment
  cloud_resource_type     = each.value.name
  instance_env            = var.environment_number
  maximum_length          = each.value.max_length
  use_azure_region_abbr   = true
}

module "resource_group" {
  source  = "terraform.registry.launch.nttdata.com/module_primitive/resource_group/azurerm"
  version = "~> 1.0"

  name     = module.resource_names["resource_group"].standard
  location = var.region

  tags = merge(var.tags, { resource_name = module.resource_names["resource_group"].standard })

}

module "vnet" {
  source  = "terraform.registry.launch.nttdata.com/module_primitive/virtual_network/azurerm"
  version = "~> 3.0"

  resource_group_name  = module.resource_group.name
  vnet_name            = module.resource_names["vnet"].standard
  vnet_location        = var.region
  address_space        = var.address_space
  subnets              = var.subnets
  bgp_community        = null
  ddos_protection_plan = null
  dns_servers          = []
  tags                 = merge(var.tags, { resource_name = module.resource_names["vnet"].standard })

  depends_on = [module.resource_group]
}

module "public_ip" {
  source  = "terraform.registry.launch.nttdata.com/module_primitive/public_ip/azurerm"
  version = "~> 1.0"

  name                = module.resource_names["public_ip"].standard
  resource_group_name = module.resource_group.name
  location            = var.region
  allocation_method   = "Static"
  domain_name_label   = module.resource_names["public_ip"].standard
  sku                 = "Standard"
  sku_tier            = "Regional"

  tags = merge(local.tags, {
    resource_name = module.resource_names["public_ip"].standard
  })

  depends_on = [module.resource_group]
}

### Must have the "bare" resource here to allow for the ignore_changes lifecycle block.
###   This is to allow for the DNS zone to be created and then the records to be created
###   without the number_of_record_sets changing and causing idempotency issues.
resource "azurerm_private_dns_zone" "apim_default_dns_zone" {
  count = var.virtual_network_type != "None" ? 1 : 0

  name                = var.dns_zone_suffix
  resource_group_name = module.resource_group.name
  tags                = local.tags
  depends_on          = [module.resource_group]
  lifecycle {
    ignore_changes = [number_of_record_sets]
  }
}

module "vnet_links" {
  source  = "terraform.registry.launch.nttdata.com/module_primitive/private_dns_vnet_link/azurerm"
  version = "~> 1.0"

  for_each = local.all_vnet_links

  link_name             = each.key
  resource_group_name   = module.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.apim_default_dns_zone[0].name
  virtual_network_id    = each.value
  registration_enabled  = false

  tags = local.tags

  depends_on = [azurerm_private_dns_zone.apim_default_dns_zone, module.resource_group]
}

module "dns_records" {
  source  = "terraform.registry.launch.nttdata.com/module_primitive/private_dns_records/azurerm"
  version = "~> 1.0"

  a_records = {
    "apim" = {
      zone_name           = azurerm_private_dns_zone.apim_default_dns_zone[0].name
      resource_group_name = module.resource_group.name
      ttl                 = var.default_ttl
      name                = module.resource_names["apim"].standard
      records             = module.apim.api_management_private_ip_addresses
    }
    "portal" = {
      zone_name           = azurerm_private_dns_zone.apim_default_dns_zone[0].name
      resource_group_name = module.resource_group.name
      ttl                 = var.default_ttl
      name                = "${module.resource_names["apim"].standard}.portal"
      records             = module.apim.api_management_private_ip_addresses
    }
    "developer" = {
      zone_name           = azurerm_private_dns_zone.apim_default_dns_zone[0].name
      resource_group_name = module.resource_group.name
      ttl                 = var.default_ttl
      name                = "${module.resource_names["apim"].standard}.developer"
      records             = module.apim.api_management_private_ip_addresses
    }
    "management" = {
      zone_name           = azurerm_private_dns_zone.apim_default_dns_zone[0].name
      resource_group_name = module.resource_group.name
      ttl                 = var.default_ttl
      name                = "${module.resource_names["apim"].standard}.management"
      records             = module.apim.api_management_private_ip_addresses
    }
    "scm" = {
      zone_name           = azurerm_private_dns_zone.apim_default_dns_zone[0].name
      resource_group_name = module.resource_group.name
      ttl                 = var.default_ttl
      name                = "${module.resource_names["apim"].standard}.scm"
      records             = module.apim.api_management_private_ip_addresses
    }
  }

  depends_on = [
    azurerm_private_dns_zone.apim_default_dns_zone,
    module.resource_group
  ]
}

module "nsg" {
  source  = "terraform.registry.launch.nttdata.com/module_primitive/network_security_group/azurerm"
  version = "~> 1.0"

  name                = module.resource_names["nsg"].standard
  location            = var.region
  resource_group_name = module.resource_group.name

  security_rules = [
    {
      name                       = "management-endpoint"
      description                = "Management endpoint for Azure portal and PowerShell"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = 3443
      source_address_prefix      = "ApiManagement"
      destination_address_prefix = "VirtualNetwork"
      access                     = "Allow"
      priority                   = 100
      direction                  = "Inbound"
    },
    {
      name                       = "load-balancer"
      description                = "Azure Infrastructure Load Balancer"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = 6390
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "VirtualNetwork"
      access                     = "Allow"
      priority                   = 101
      direction                  = "Inbound"
    },
    {
      name                       = "azure-storage"
      description                = "Dependency on Azure Storage for core service functionality"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = 443
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "Storage"
      access                     = "Allow"
      priority                   = 102
      direction                  = "Outbound"
    },
    {
      name                       = "azure-sql"
      description                = "Access to Azure SQL endpoints for core service functionality"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = 1443
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "SQL"
      access                     = "Allow"
      priority                   = 103
      direction                  = "Outbound"
    },
    {
      name                       = "azure-key-vault"
      description                = "Access to Azure Key Vault for core service functionality"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = 443
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "AzureKeyVault"
      access                     = "Allow"
      priority                   = 104
      direction                  = "Outbound"
    },
    {
      name                       = "azure-monitor"
      description                = "Publish Diagnostics Logs and Metrics, Resource Health, and Application Insights"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = [1886, 443]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "AzureMonitor"
      access                     = "Allow"
      priority                   = 105
      direction                  = "Outbound"
    }
  ]

  tags = merge(local.tags, {
    resource_name = module.resource_names["nsg"].standard
  })

  depends_on = [module.resource_group]
}

module "nsg_subnet_assoc" {
  source                    = "terraform.registry.launch.nttdata.com/module_primitive/nsg_subnet_association/azurerm"
  version                   = "~> 1.0"
  subnet_id                 = module.vnet.subnet_map["default"].id
  network_security_group_id = module.nsg.network_security_group_id

  depends_on = [module.nsg]
}

module "managed_identity" {
  source                      = "terraform.registry.launch.nttdata.com/module_primitive/user_managed_identity/azurerm"
  version                     = "~> 1.0"
  count                       = var.identity_type == "SystemAssigned" ? 0 : 1
  resource_group_name         = module.resource_group.name
  location                    = var.region
  user_assigned_identity_name = module.resource_names["msi"].standard
  tags = merge(local.tags, {
    resource_name = module.resource_names["msi"].standard
  })
  depends_on = [module.resource_group]
}

module "apim" {
  source = "../.."

  name                = module.resource_names["apim"].standard
  location            = var.region
  resource_group_name = module.resource_group.name

  publisher_name  = var.publisher_name
  publisher_email = var.publisher_email
  sku_name        = var.sku_name
  zones           = var.zones

  public_network_access_enabled = var.public_network_access_enabled
  public_ip_address_id          = module.public_ip.id

  additional_location = var.additional_location

  certificate_configuration = var.certificate_configuration

  client_certificate_enabled = var.client_certificate_enabled
  gateway_disabled           = var.gateway_disabled
  min_api_version            = var.min_api_version

  identity_type = var.identity_type
  identity_ids  = var.identity_ids == null ? [] : concat(var.identity_ids, [module.managed_identity[0].id])

  management_hostname_configuration       = var.management_hostname_configuration
  portal_hostname_configuration           = var.portal_hostname_configuration
  developer_portal_hostname_configuration = var.developer_portal_hostname_configuration
  proxy_hostname_configuration            = var.proxy_hostname_configuration

  scm_hostname_configuration = var.scm_hostname_configuration
  policy_configuration       = var.policy_configuration


  notification_sender_email = var.notification_sender_email

  enable_http2 = var.enable_http2

  security_configuration = var.security_configuration

  enable_sign_in = var.enable_sign_in
  enable_sign_up = var.enable_sign_up


  terms_of_service_configuration = var.terms_of_service_configuration
  virtual_network_configuration  = [module.vnet.subnet_map["default"].id]

  virtual_network_type = var.virtual_network_type

  tags = local.tags

  depends_on = [module.resource_group, module.public_ip]
}
