resource "azurerm_linux_virtual_machine_scale_set" "linux_vm_scale_set" {

  // Forces acceptance of marketplace terms before creating a VM
  depends_on = [
    azurerm_marketplace_agreement.plan_acceptance_simple,
    azurerm_marketplace_agreement.plan_acceptance_custom
  ]

  for_each            = var.scale_sets
  name                = each.key
  resource_group_name = var.rg_name
  location            = var.location
  tags                = var.tags

  computer_name_prefix                              = try(each.value.computer_name_prefix, null)
  admin_username                                    = try(each.value.admin_username, null)
  admin_password                                    = try(each.value.admin_password, null)
  edge_zone                                         = try(each.value.edge_zone, null)
  instances                                         = try(each.value.instances, null)
  sku                                               = try(each.value.vm_size, null)
  custom_data                                       = try(each.value.custom_data, null)
  disable_password_authentication                   = each.value.disable_password_authentication
  do_not_run_extensions_on_overprovisioned_machines = try(each.value.do_not_run_extensions_on_overprovisioned_machines, null)
  extensions_time_budget                            = try(each.value.do_not_run_extensions_on_overprovisioned_machines, null)
  #checkov:skip=CKV_AZURE_151:Ensure Encryption at host is enabled
  encryption_at_host_enabled = try(each.value.encryption_at_host_enabled, null)

  #checkov:skip=CKV_AZURE_50:Ensure Virtual Machine extensions are not installed
  provision_vm_agent = try(each.value.provision_vm_agent, null)


  priority        = var.spot_instance ? "Spot" : "Regular"
  max_bid_price   = var.spot_instance ? var.spot_instance_max_bid_price : null
  eviction_policy = var.spot_instance ? var.spot_instance_eviction_policy : null


  dynamic "os_disk" {
    for_each = lookup(var.settings[each.key], "os_disk", {}) != {} ? [1] : []
    content {
      name                      = try(each.value.name, "${each.key}-osdisk", null)
      caching                   = try(each.value.caching, "ReadWrite", null)
      storage_account_type      = try(each.value.storage_account_type, "StandardSSD_LRS", null)
      disk_size_gb              = try(each.value.disk_size_gb, "127", null)
      disk_iops_read_write      = try(each.value.disk_iops_read_write, null)
      disk_mbps_read_write      = try(each.value.disk_mbps_read_write, null)
      write_accelerator_enabled = try(each.value.write_accelerator_enabled, null)
      disk_encryption_set_id    = try(each.value.disk_encryption_set_id, null)

      dynamic "diff_disk_settings" {
        for_each = lookup(var.settings[each.key].os_disk, "diff_disk_settings", {}) != {} ? [1] : []
        content {
          option = try(each.value.option, null)
        }
      }
    }
  }

  dynamic "data_disk" {
    for_each = lookup(var.settings[each.key], "data_disk", {}) != {} ? [1] : []
    content {
      name                      = try(each.value.name, "${each.key}-osdisk", null)
      caching                   = try(each.value.caching, "ReadWrite", null)
      lun                       = try(each.value.lun, null)
      storage_account_type      = try(each.value.storage_account_type, "StandardSSD_LRS", null)
      disk_size_gb              = try(each.value.disk_size_gb, "127", null)
      disk_iops_read_write      = try(each.value.disk_iops_read_write, null)
      disk_mbps_read_write      = try(each.value.disk_mbps_read_write, null)
      write_accelerator_enabled = try(each.value.write_accelerator_enabled, null)
      disk_encryption_set_id    = try(each.value.disk_encryption_set_id, null)

      dynamic "diff_disk_settings" {
        for_each = lookup(var.settings[each.key].data_disk, "diff_disk_settings", {}) != {} ? [1] : []
        content {
          option = try(each.value.option, null)
        }
      }
    }
  }

  dynamic "extension" {
    for_each = lookup(var.settings[each.key], "extension", {}) != {} ? [1] : []
    content {

      name                       = lookup(var.settings[each.key].extension, "name", null)
      publisher                  = lookup(var.settings[each.key].extension, "publisher", null)
      type                       = lookup(var.settings[each.key].extension, "type", null)
      type_handler_version       = lookup(var.settings[each.key].extension, "type_handler_version", null)
      auto_upgrade_minor_version = lookup(var.settings[each.key].extension, "auto_upgrade_minor_version", null)
      automatic_upgrade_enabled  = lookup(var.settings[each.key].extension, "automatic_upgrade_enabled", null)
      force_update_tag           = lookup(var.settings[each.key].extension, "force_update_tag", null)
      provision_after_extensions = tolist(lookup(var.settings[each.key].extension, "provision_after_extensions", null))
      settings                   = lookup(var.settings[each.key].extension, "settings", null)
      protected_settings         = lookup(var.settings[each.key].extension, "protected_settings", null)
    }
  }

  dynamic "boot_diagnostics" {
    for_each = lookup(var.settings[each.key], "boot_diagnostics", {}) != {} ? [1] : []
    content {
      storage_account_uri = try(each.value.storage_account_uri, null)
    }
  }

  dynamic "additional_capabilities" {
    for_each = lookup(var.settings[each.key], "additional_capabilities", {}) != {} ? [1] : []
    content {
      ultra_ssd_enabled = lookup(var.settings[each.key].additional_capabilities, "ultra_ssd_enabled", false)
    }
  }

  dynamic "automatic_os_upgrade_policy" {
    for_each = lookup(var.settings[each.key], "automatic_os_upgrade_policy", {}) != {} ? [1] : []
    content {

      disable_automatic_rollback  = lookup(var.settings[each.key].automatic_os_upgrade_policy, "disable_automatic_rollback", false)
      enable_automatic_os_upgrade = lookup(var.settings[each.key].automatic_os_upgrade_policy, "enable_automatic_os_upgrade", true)
    }
  }

  dynamic "automatic_instance_repair" {
    for_each = lookup(var.settings[each.key], "automatic_instance_repair", {}) != {} ? [1] : []
    content {

      enabled      = lookup(var.settings[each.key].automatic_instance_repair, "enabled", true)
      grace_period = lookup(var.settings[each.key].automatic_instance_repair, "grace_period", null)
    }
  }

  dynamic "network_interface" {
    for_each = lookup(var.settings, "network_interface", {}) != {} ? [1] : []
    content {
      name                          = lookup(var.settings[each.key].network_interface, "name", null)
      primary                       = lookup(var.settings[each.key].network_interface, "primary", null)
      network_security_group_id     = lookup(var.settings[each.key].network_interface, "network_security_group_id", null)
      enable_accelerated_networking = lookup(var.settings[each.key].network_interface, "enable_accelerated_networking", null)
      enable_ip_forwarding          = lookup(var.settings[each.key].network_interface, "enable_ip_forwarding", null)
      dns_servers                   = tolist(lookup(var.settings[each.key].network_interface, "dns_servers", null))

      dynamic "ip_configuration" {
        for_each = lookup(var.settings[each.key].network_interface, "ip_configuration", {}) != {} ? [1] : []
        content {
          name                                         = lookup(var.settings[each.key].network_interface.ip_configuration, "name", null)
          primary                                      = lookup(var.settings[each.key].network_interface.ip_configuration, "primary", null)
          application_gateway_backend_address_pool_ids = lookup(var.settings[each.key].network_interface.ip_configuration, "application_gateway_backend_address_pool_ids", null)
          application_security_group_ids               = lookup(var.settings[each.key].network_interface.ip_configuration, "application_security_group_ids", null)
          load_balancer_backend_address_pool_ids       = lookup(var.settings[each.key].network_interface.ip_configuration, "load_balancer_backend_address_pool_ids", null)
          load_balancer_inbound_nat_rules_ids          = lookup(var.settings[each.key].network_interface.ip_configuration, "load_balancer_inbound_nat_rules_ids", null)
          version                                      = lookup(var.settings[each.key].network_interface.ip_configuration, "version", null)
          subnet_id                                    = lookup(var.settings[each.key].network_interface.ip_configuration, "subnet_id", null)

          dynamic "public_ip_address" {
            for_each = lookup(var.settings.network_interface.ip_configuration, "public_ip_address", {}) != {} ? [1] : []
            content {
              name                    = lookup(var.settings[each.key].network_interface.ip_configuration.public_ip_address, "name", null)
              domain_name_label       = lookup(var.settings[each.key].network_interface.ip_configuration.public_ip_address, "domain_name_label", null)
              idle_timeout_in_minutes = lookup(var.settings[each.key].network_interface.ip_configuration.public_ip_address, "idle_timeout_in_minutes", null)
              public_ip_prefix_id     = lookup(var.settings[each.key].network_interface.ip_configuration.public_ip_address, "public_ip_prefix_id ", null)

              dynamic "ip_tag" {
                for_each = lookup(var.settings[each.key].network_interface.ip_configuration.public_ip_address, "public_ip_address", {}) != {} ? [1] : []
                content {
                  type = lookup(var.settings[each.key].network_interface.ip_configuration.public_ip_address.ip_tag, "type", null)
                  tag  = lookup(var.settings[each.key].network_interface.ip_configuration.public_ip_address.ip_tag, "tag", null)
                }
              }
            }
          }
        }
      }
    }
  }

  // Uses calculator
  dynamic "source_image_reference" {
    for_each = try(var.use_simple_image, null) == true && try(var.use_simple_image_with_plan, null) == false ? [1] : []
    content {
      publisher = var.vm_os_id == "" ? coalesce(var.vm_os_publisher, module.os_calculator[0].calculated_value_os_publisher) : ""
      offer     = var.vm_os_id == "" ? coalesce(var.vm_os_offer, module.os_calculator[0].calculated_value_os_offer) : ""
      sku       = var.vm_os_id == "" ? coalesce(var.vm_os_sku, module.os_calculator[0].calculated_value_os_sku) : ""
      version   = var.vm_os_id == "" ? var.vm_os_version : ""
    }
  }

  // Uses your own source image
  dynamic "source_image_reference" {
    for_each = try(var.use_simple_image, null) == false && try(var.use_simple_image_with_plan, null) == false && length(var.source_image_reference) > 0 && length(var.plan) == 0 ? [1] : []
    content {
      publisher = lookup(var.source_image_reference, "publisher", null)
      offer     = lookup(var.source_image_reference, "offer", null)
      sku       = lookup(var.source_image_reference, "sku", null)
      version   = lookup(var.source_image_reference, "version", null)
    }
  }

  // To be used when a VM with a plan is used
  dynamic "source_image_reference" {
    for_each = try(var.use_simple_image, null) == true && try(var.use_simple_image_with_plan, null) == true ? [1] : []
    content {
      publisher = var.vm_os_id == "" ? coalesce(var.vm_os_publisher, module.os_calculator_with_plan[0].calculated_value_os_publisher) : ""
      offer     = var.vm_os_id == "" ? coalesce(var.vm_os_offer, module.os_calculator_with_plan[0].calculated_value_os_offer) : ""
      sku       = var.vm_os_id == "" ? coalesce(var.vm_os_sku, module.os_calculator_with_plan[0].calculated_value_os_sku) : ""
      version   = var.vm_os_id == "" ? var.vm_os_version : ""
    }
  }

  dynamic "plan" {
    for_each = try(var.use_simple_image, null) == true && try(var.use_simple_image_with_plan, null) == true ? [1] : []
    content {
      name      = var.vm_os_id == "" ? coalesce(var.vm_os_sku, module.os_calculator_with_plan[0].calculated_value_os_sku) : ""
      product   = var.vm_os_id == "" ? coalesce(var.vm_os_offer, module.os_calculator_with_plan[0].calculated_value_os_offer) : ""
      publisher = var.vm_os_id == "" ? coalesce(var.vm_os_publisher, module.os_calculator_with_plan[0].calculated_value_os_publisher) : ""
    }
  }

  // Uses your own image with custom plan
  dynamic "source_image_reference" {
    for_each = try(var.use_simple_image, null) == false && try(var.use_simple_image_with_plan, null) == false && length(var.plan) > 0 ? [1] : []
    content {
      publisher = lookup(var.source_image_reference, "publisher", null)
      offer     = lookup(var.source_image_reference, "offer", null)
      sku       = lookup(var.source_image_reference, "sku", null)
      version   = lookup(var.source_image_reference, "version", null)
    }
  }

  dynamic "plan" {
    for_each = try(var.use_simple_image, null) == false && try(var.use_simple_image_with_plan, null) == false && length(var.plan) > 0 ? [1] : []
    content {
      name      = lookup(var.plan, "name", null)
      product   = lookup(var.plan, "product", null)
      publisher = lookup(var.plan, "publisher", null)
    }
  }
  dynamic "admin_ssh_key" {
    for_each = var.ssh_public_key != null ? ["fake"] : []
    content {
      public_key = var.ssh_public_key
      username   = var.admin_username
    }
  }

  dynamic "identity" {
    for_each = length(var.identity_ids) == 0 && var.identity_type == "SystemAssigned" ? [var.identity_type] : []
    content {
      type = var.identity_type
    }
  }

  dynamic "identity" {
    for_each = length(var.identity_ids) > 0 || var.identity_type == "UserAssigned" ? [var.identity_type] : []
    content {
      type         = var.identity_type
      identity_ids = length(var.identity_ids) > 0 ? var.identity_ids : []
    }
  }

}

module "os_calculator" {
  source = "registry.terraform.io/libre-devops/linux-os-sku-calculator/azurerm"

  count = try(var.use_simple_image, null) == true ? 1 : 0

  vm_os_simple = var.vm_os_simple
}

module "os_calculator_with_plan" {
  source = "registry.terraform.io/libre-devops/linux-os-sku-with-plan-calculator/azurerm"

  count = try(var.use_simple_image_with_plan, null) == true ? 1 : 0

  vm_os_simple = var.vm_os_simple
}

// Use these modules and accept these terms at your own peril
resource "azurerm_marketplace_agreement" "plan_acceptance_simple" {
  count = try(var.use_simple_image_with_plan, null) == true ? 1 : 0

  publisher = coalesce(var.vm_os_publisher, module.os_calculator_with_plan[0].calculated_value_os_publisher)
  offer     = coalesce(var.vm_os_offer, module.os_calculator_with_plan[0].calculated_value_os_offer)
  plan      = coalesce(var.vm_os_sku, module.os_calculator_with_plan[0].calculated_value_os_sku)
}

// Use these modules and accept these terms at your own peril
resource "azurerm_marketplace_agreement" "plan_acceptance_custom" {
  count = try(var.use_simple_image, null) == false && try(var.use_simple_image_with_plan, null) == false && length(var.plan) > 0 ? 1 : 0

  publisher = lookup(var.plan, "publisher", null)
  offer     = lookup(var.plan, "product", null)
  plan      = lookup(var.plan, "name", null)
}