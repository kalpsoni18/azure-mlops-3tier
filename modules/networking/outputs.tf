output "vnet_id" { value = azurerm_virtual_network.main.id }
output "vnet_name" { value = azurerm_virtual_network.main.name }
output "public_subnet_id" { value = azurerm_subnet.public.id }
output "private_subnet_id" { value = azurerm_subnet.private.id }
output "database_subnet_id" { value = azurerm_subnet.database.id }
output "aks_subnet_id" { value = azurerm_subnet.aks.id }
output "private_dns_zone_id" { value = azurerm_private_dns_zone.postgres.id }
