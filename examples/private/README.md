# api-management
Creates a Private API Management instance in a VNet. The SKU is `Developer` and the networking mode is `Internal`.
Only other SKU that supports completely private APIM is `Premium`.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.5 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~>3.67 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.6 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_resource_names"></a> [resource\_names](#module\_resource\_names) | terraform.registry.launch.nttdata.com/module_library/resource_name/launch | ~> 1.0 |
| <a name="module_resource_group"></a> [resource\_group](#module\_resource\_group) | terraform.registry.launch.nttdata.com/module_primitive/resource_group/azurerm | ~> 1.0 |
| <a name="module_vnet"></a> [vnet](#module\_vnet) | terraform.registry.launch.nttdata.com/module_primitive/virtual_network/azurerm | ~> 2.0 |
| <a name="module_public_ip"></a> [public\_ip](#module\_public\_ip) | terraform.registry.launch.nttdata.com/module_primitive/public_ip/azurerm | ~> 1.0 |
| <a name="module_apim_default_dns_zone"></a> [apim\_default\_dns\_zone](#module\_apim\_default\_dns\_zone) | terraform.registry.launch.nttdata.com/module_primitive/private_dns_zone/azurerm | ~> 1.0 |
| <a name="module_vnet_links"></a> [vnet\_links](#module\_vnet\_links) | terraform.registry.launch.nttdata.com/module_primitive/private_dns_vnet_link/azurerm | ~> 1.0 |
| <a name="module_dns_records"></a> [dns\_records](#module\_dns\_records) | terraform.registry.launch.nttdata.com/module_primitive/private_dns_records/azurerm | ~> 1.0 |
| <a name="module_nsg"></a> [nsg](#module\_nsg) | terraform.registry.launch.nttdata.com/module_primitive/network_security_group/azurerm | ~> 1.0 |
| <a name="module_nsg_subnet_assoc"></a> [nsg\_subnet\_assoc](#module\_nsg\_subnet\_assoc) | terraform.registry.launch.nttdata.com/module_primitive/nsg_subnet_association/azurerm | ~> 1.0 |
| <a name="module_apim"></a> [apim](#module\_apim) | ../.. | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_product_family"></a> [product\_family](#input\_product\_family) | (Required) Name of the product family for which the resource is created.<br>    Example: org\_name, department\_name. | `string` | `"dso"` | no |
| <a name="input_product_service"></a> [product\_service](#input\_product\_service) | (Required) Name of the product service for which the resource is created.<br>    For example, backend, frontend, middleware etc. | `string` | `"kube"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment in which the resource should be provisioned like dev, qa, prod etc. | `string` | `"dev"` | no |
| <a name="input_environment_number"></a> [environment\_number](#input\_environment\_number) | The environment count for the respective environment. Defaults to 000. Increments in value of 1 | `string` | `"000"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region in which the infra needs to be provisioned | `string` | `"eastus"` | no |
| <a name="input_resource_names_map"></a> [resource\_names\_map](#input\_resource\_names\_map) | A map of key to resource\_name that will be used by tf-launch-module\_library-resource\_name to generate resource names | <pre>map(object(<br>    {<br>      name       = string<br>      max_length = optional(number, 60)<br>    }<br>  ))</pre> | <pre>{<br>  "apim": {<br>    "max_length": 60,<br>    "name": "apim"<br>  },<br>  "key_vault": {<br>    "max_length": 24,<br>    "name": "kv"<br>  },<br>  "nsg": {<br>    "max_length": 60,<br>    "name": "nsg"<br>  },<br>  "public_ip": {<br>    "max_length": 60,<br>    "name": "pip"<br>  },<br>  "resource_group": {<br>    "max_length": 60,<br>    "name": "rg"<br>  },<br>  "route_table": {<br>    "max_length": 60,<br>    "name": "rt"<br>  },<br>  "vnet": {<br>    "max_length": 60,<br>    "name": "vnet"<br>  }<br>}</pre> | no |
| <a name="input_address_space"></a> [address\_space](#input\_address\_space) | Address space of the Vnet | `list(string)` | <pre>[<br>  "10.51.0.0/16"<br>]</pre> | no |
| <a name="input_subnet_names"></a> [subnet\_names](#input\_subnet\_names) | Name of the subnets to be created | `list(string)` | <pre>[<br>  "subnet-apim"<br>]</pre> | no |
| <a name="input_subnet_prefixes"></a> [subnet\_prefixes](#input\_subnet\_prefixes) | The CIDR blocks of the subnets whose names are specified in `subnet_names` | `list(string)` | <pre>[<br>  "10.51.0.0/24"<br>]</pre> | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group | `string` | `null` | no |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | String consisting of two parts separated by an underscore. The fist part is the name, valid values include: Developer,<br>    Basic, Standard and Premium. The second part is the capacity. Default is Developer\_1. | `string` | `"Developer_1"` | no |
| <a name="input_publisher_name"></a> [publisher\_name](#input\_publisher\_name) | The name of publisher/company. | `string` | n/a | yes |
| <a name="input_publisher_email"></a> [publisher\_email](#input\_publisher\_email) | The email of publisher/company. | `string` | n/a | yes |
| <a name="input_additional_location"></a> [additional\_location](#input\_additional\_location) | List of the name of the Azure Region in which the API Management Service should be expanded to. | `list(map(string))` | `[]` | no |
| <a name="input_zones"></a> [zones](#input\_zones) | (Optional) Specifies a list of Availability Zones in which this API Management service should be located. Changing this forces a new API Management service to be created. Supported in Premium Tier. | `list(number)` | `[]` | no |
| <a name="input_certificate_configuration"></a> [certificate\_configuration](#input\_certificate\_configuration) | List of certificate configurations | <pre>list(object({<br>    encoded_certificate  = string<br>    certificate_password = string<br>    store_name           = string<br>  }))</pre> | `[]` | no |
| <a name="input_client_certificate_enabled"></a> [client\_certificate\_enabled](#input\_client\_certificate\_enabled) | (Optional) Enforce a client certificate to be presented on each request to the gateway? This is only supported when SKU type is `Consumption`. | `bool` | `false` | no |
| <a name="input_gateway_disabled"></a> [gateway\_disabled](#input\_gateway\_disabled) | (Optional) Disable the gateway in main region? This is only supported when `additional_location` is set. | `bool` | `false` | no |
| <a name="input_min_api_version"></a> [min\_api\_version](#input\_min\_api\_version) | (Optional) The version which the control plane API calls to API Management service are limited with version equal to or newer than. | `string` | `null` | no |
| <a name="input_enable_http2"></a> [enable\_http2](#input\_enable\_http2) | Should HTTP/2 be supported by the API Management Service? | `bool` | `false` | no |
| <a name="input_management_hostname_configuration"></a> [management\_hostname\_configuration](#input\_management\_hostname\_configuration) | List of management hostname configurations | `list(map(string))` | `[]` | no |
| <a name="input_scm_hostname_configuration"></a> [scm\_hostname\_configuration](#input\_scm\_hostname\_configuration) | List of scm hostname configurations | `list(map(string))` | `[]` | no |
| <a name="input_proxy_hostname_configuration"></a> [proxy\_hostname\_configuration](#input\_proxy\_hostname\_configuration) | List of proxy hostname configurations | `list(map(string))` | `[]` | no |
| <a name="input_portal_hostname_configuration"></a> [portal\_hostname\_configuration](#input\_portal\_hostname\_configuration) | Legacy portal hostname configurations | `list(map(string))` | `[]` | no |
| <a name="input_developer_portal_hostname_configuration"></a> [developer\_portal\_hostname\_configuration](#input\_developer\_portal\_hostname\_configuration) | Developer portal hostname configurations | `list(map(string))` | `[]` | no |
| <a name="input_notification_sender_email"></a> [notification\_sender\_email](#input\_notification\_sender\_email) | Email address from which the notification will be sent | `string` | `null` | no |
| <a name="input_policy_configuration"></a> [policy\_configuration](#input\_policy\_configuration) | Map of policy configuration | `map(string)` | `{}` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Should the API Management Service be accessible from the public internet?<br>    This option is applicable only to the Management plane, not the API gateway or Developer portal.<br>    It is required to be true on the creation. | `bool` | `true` | no |
| <a name="input_enable_sign_in"></a> [enable\_sign\_in](#input\_enable\_sign\_in) | Should anonymous users be redirected to the sign in page? | `bool` | `false` | no |
| <a name="input_enable_sign_up"></a> [enable\_sign\_up](#input\_enable\_sign\_up) | Can users sign up on the development portal? | `bool` | `false` | no |
| <a name="input_terms_of_service_configuration"></a> [terms\_of\_service\_configuration](#input\_terms\_of\_service\_configuration) | Map of terms of service configuration | `list(map(string))` | <pre>[<br>  {<br>    "consent_required": false,<br>    "enabled": false,<br>    "text": ""<br>  }<br>]</pre> | no |
| <a name="input_security_configuration"></a> [security\_configuration](#input\_security\_configuration) | Map of security configuration | `map(string)` | `{}` | no |
| <a name="input_virtual_network_type"></a> [virtual\_network\_type](#input\_virtual\_network\_type) | The type of virtual network you want to use, valid values include: None, External, Internal. | `string` | `"None"` | no |
| <a name="input_identity_type"></a> [identity\_type](#input\_identity\_type) | Type of Managed Service Identity that should be configured on this API Management Service | `string` | `"SystemAssigned"` | no |
| <a name="input_identity_ids"></a> [identity\_ids](#input\_identity\_ids) | A list of IDs for User Assigned Managed Identity resources to be assigned. This is required when type is set to UserAssigned or SystemAssigned, UserAssigned. | `list(string)` | `null` | no |
| <a name="input_dns_zone_suffix"></a> [dns\_zone\_suffix](#input\_dns\_zone\_suffix) | The DNS Zone suffix for APIM private DNS Zone. Default is `azure-api.net` for Public Cloud<br>    For gov cloud it may be different | `string` | `"azure-api.net"` | no |
| <a name="input_default_ttl"></a> [default\_ttl](#input\_default\_ttl) | The default TTL for the DNS Zone | `number` | `300` | no |
| <a name="input_additional_vnet_links"></a> [additional\_vnet\_links](#input\_additional\_vnet\_links) | A list of VNET IDs for which vnet links to be created with the private AKS cluster DNS Zone. Applicable only when private\_cluster\_enabled is true. | `map(string)` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the resource. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_management_name"></a> [api\_management\_name](#output\_api\_management\_name) | The name of the API Management Service |
| <a name="output_api_management_id"></a> [api\_management\_id](#output\_api\_management\_id) | The ID of the API Management Service |
| <a name="output_api_management_additional_location"></a> [api\_management\_additional\_location](#output\_api\_management\_additional\_location) | Map listing gateway\_regional\_url and public\_ip\_addresses associated |
| <a name="output_api_management_gateway_url"></a> [api\_management\_gateway\_url](#output\_api\_management\_gateway\_url) | The URL of the Gateway for the API Management Service |
| <a name="output_api_management_gateway_regional_url"></a> [api\_management\_gateway\_regional\_url](#output\_api\_management\_gateway\_regional\_url) | The Region URL for the Gateway of the API Management Service |
| <a name="output_api_management_management_api_url"></a> [api\_management\_management\_api\_url](#output\_api\_management\_management\_api\_url) | The URL for the Management API associated with this API Management service |
| <a name="output_api_management_portal_url"></a> [api\_management\_portal\_url](#output\_api\_management\_portal\_url) | The URL for the Publisher Portal associated with this API Management service |
| <a name="output_api_management_public_ip_addresses"></a> [api\_management\_public\_ip\_addresses](#output\_api\_management\_public\_ip\_addresses) | The Public IP addresses of the API Management Service |
| <a name="output_api_management_private_ip_addresses"></a> [api\_management\_private\_ip\_addresses](#output\_api\_management\_private\_ip\_addresses) | The Private IP addresses of the API Management Service |
| <a name="output_api_management_scm_url"></a> [api\_management\_scm\_url](#output\_api\_management\_scm\_url) | The URL for the SCM Endpoint associated with this API Management service |
| <a name="output_api_management_identity"></a> [api\_management\_identity](#output\_api\_management\_identity) | The identity of the API Management |
| <a name="output_public_ip_address"></a> [public\_ip\_address](#output\_public\_ip\_address) | n/a |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
