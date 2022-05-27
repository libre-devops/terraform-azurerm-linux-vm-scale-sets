module "rg" {
  source = "registry.terraform.io/libre-devops/rg/azurerm"

  rg_name  = "rg-${var.short}-${var.loc}-${terraform.workspace}-build" // rg-ldo-euw-dev-build
  location = local.location                                            // compares var.loc with the var.regions var to match a long-hand name, in this case, "euw", so "westeurope"
  tags     = local.tags

  #  lock_level = "CanNotDelete" // Do not set this value to skip lock
}

module "network" {
  source = "registry.terraform.io/libre-devops/network/azurerm"

  rg_name  = module.rg.rg_name // rg-ldo-euw-dev-build
  location = module.rg.rg_location
  tags     = local.tags

  vnet_name     = "vnet-${var.short}-${var.loc}-${terraform.workspace}-01" // vnet-ldo-euw-dev-01
  vnet_location = module.network.vnet_location

  address_space   = ["10.0.0.0/16"]
  subnet_prefixes = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  subnet_names    = ["sn1-${module.network.vnet_name}", "sn2-${module.network.vnet_name}", "sn3-${module.network.vnet_name}"] //sn1-vnet-ldo-euw-dev-01
  subnet_service_endpoints = {
    "sn1-${module.network.vnet_name}" = ["Microsoft.Storage"]                   // Adds extra subnet endpoints to sn1-vnet-ldo-euw-dev-01
    "sn2-${module.network.vnet_name}" = ["Microsoft.Storage", "Microsoft.Sql"], // Adds extra subnet endpoints to sn2-vnet-ldo-euw-dev-01
    "sn3-${module.network.vnet_name}" = ["Microsoft.AzureActiveDirectory"]      // Adds extra subnet endpoints to sn3-vnet-ldo-euw-dev-01
  }
}

module "nsg" {
  source = "registry.terraform.io/libre-devops/nsg/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  nsg_name  = "nsg-${var.short}-${var.loc}-${terraform.workspace}-01"
  subnet_id = element(values(module.network.subnets_ids), 0)

}

module "linux_scale_set" {
  source = "registry.terraform.io/libre-devops/linux-vm-scale-sets/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  ssh_public_key   = data.azurerm_ssh_public_key.mgmt_ssh_key.public_key
  use_simple_image = true
  vm_os_simple     = "Ubuntu20.04"
  identity_type    = "SystemAssigned"
  asg_name         = "asg-vmss${var.short}${var.loc}${terraform.workspace}-${var.short}-${var.loc}-${terraform.workspace}-01"


  settings = {
    "vmss${var.short}${var.loc}${terraform.workspace}01" = {

      admin_username                  = "LibreDevops"
      sku                             = "Standard_B4ms"
      disable_password_authentication = true
      instances                       = 2
      overprovision                   = false
      zones                           = ["1"]
      provision_vm_agent              = true

      os_disk = {
        storage_account_type = "Standard_LRS"
        disk_size_gb         = "127"
      }

      network_interface = {
        network_security_group_id = module.nsg.nsg_id

        ip_configuration = {
          subnet_id = element(values(module.network.subnets_ids), 0)
        }
      }
    }
  }
}

