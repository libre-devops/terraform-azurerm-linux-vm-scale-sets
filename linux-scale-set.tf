resource "azurerm_linux_virtual_machine_scale_set" "linux_vm_scale_set" {

  // Forces acceptance of marketplace terms before creating a VM
  depends_on = [
    azurerm_marketplace_agreement.plan_acceptance_simple,
    azurerm_marketplace_agreement.plan_acceptance_custom
  ]

  for_each            = var.settings
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
  disable_password_authentication                   = try(each.value.disable_password_authenticationm, null)
  do_not_run_extensions_on_overprovisioned_machines = try(each.value.do_not_run_extensions_on_overprovisioned_machines, null)
  extensions_time_budget                            = try(each.value.do_not_run_extensions_on_overprovisioned_machines, null)
  priority                                          = try(each.value.priority, null)
  max_bid_price                                     = try(each.value.max_bid_price, null)
  eviction_policy                                   = try(each.value.eviction_policy, null)
  health_probe_id                                   = try(each.value.health_probe_id, null)
  overprovision                                     = try(each.value.overprovision, true)
  platform_fault_domain_count                       = try(each.value.platform_fault_domain_count, null)
  upgrade_mode                                      = try(each.value.upgrade_mode, null)
  proximity_placement_group_id                      = try(each.value.proximity_placement_group_id, null)
  scale_in_policy                                   = try(each.value.scale_in_policy, null)
  secure_boot_enabled                               = try(each.value.secure_boot_enabled, null)
  single_placement_group                            = try(each.value.single_placement_group, null)
  source_image_id                                   = try(each.value.source_image_id, null)
  vtpm_enabled                                      = try(each.value.vtpm_enabled, null)
  zone_balance                                      = try(each.value.zone_balanace, null)
  zones                                             = tolist(try(each.value.zones, null))


  #checkov:skip=CKV_AZURE_151:Ensure Encryption at host is enabled
  encryption_at_host_enabled = try(each.value.encryption_at_host_enabled, null)

  #checkov:skip=CKV_AZURE_50:Ensure Virtual Machine extensions are not installed
  provision_vm_agent = try(each.value.provision_vm_agent, null)

  dynamic "rolling_upgrade_policy" {
    for_each = lookup(var.settings[each.key], "rolling_upgrade_policy", {}) != {} ? [1] : []
    content {
      max_batch_instance_percent              = lookup(var.settings[each.key].rolling_upgrade_policy, "max_batch_instance_percent", null)
      max_unhealthy_instance_percent          = lookup(var.settings[each.key].rolling_upgrade_policy, "max_unhealthy_instance_percent", null)
      max_unhealthy_upgraded_instance_percent = lookup(var.settings[each.key].rolling_upgrade_policy, "max_unhealthy_upgraded_instance_percent", null)
      pause_time_between_batches              = lookup(var.settings[each.key].rolling_upgrade_policy, "pause_time_between_batches", null)
    }
  }

  # To be removed in version 4 of the provider
  dynamic "terminate_notification" {
    for_each = lookup(var.settings[each.key], "terminate_notification", {}) != {} ? [1] : []
    content {
      enabled = lookup(var.settings[each.key].terminate_notification, "enabled", null)
      timeout = lookup(var.settings[each.key].terminate_notification, "timeout", null)
    }
  }

  # To be removed in version 4 of the provider
  dynamic "termination_notification" {
    for_each = lookup(var.settings[each.key], "termination_notification", {}) != {} ? [1] : []
    content {
      enabled = lookup(var.settings[each.key].terminate_notification, "enabled", null)
      timeout = lookup(var.settings[each.key].terminate_notification, "timeout", null)
    }
  }

  dynamic "secret" {
    for_each = lookup(var.settings[each.key], "secret", {}) != {} ? [1] : []
    content {
      key_vault_id = lookup(var.settings[each.key].secret, "key_vault_id", null)

      dynamic "certificate" {
        for_each = lookup(var.settings[each.key].secret, "certificate", {}) != {} ? [1] : []
        content {
          url = lookup(var.settings[each.key].secret.certificate, "url", null)
        }
      }
    }
  }

  dynamic "os_disk" {
    for_each = lookup(var.settings[each.key], "os_disk", {}) != {} ? [1] : []
    content {
      caching                   = lookup(var.settings[each.key].os_disk, "caching", "ReadWrite")
      storage_account_type      = lookup(var.settings[each.key].os_disk, "storage_account_type", "StandardSSD_LRS")
      disk_size_gb              = lookup(var.settings[each.key].os_disk, "disk_size_gb", null)
      write_accelerator_enabled = lookup(var.settings[each.key].os_disk, "write_accelerator_enabled", null)
      disk_encryption_set_id    = lookup(var.settings[each.key].os_disk, "disk_encryption_set_id", null)

      dynamic "diff_disk_settings" {
        for_each = lookup(var.settings[each.key].os_disk, "diff_disk_settings", {}) != {} ? [1] : []
        content {
          option = lookup(var.settings[each.key].os_disk.diff_disk_settings, "option", null)
        }
      }
    }
  }

  dynamic "data_disk" {
    for_each = lookup(var.settings[each.key], "data_disk", {}) != {} ? [1] : []
    content {
      lun                       = lookup(var.settings[each.key].data_disk, "lun", null)
      caching                   = lookup(var.settings[each.key].data_disk, "caching", null)
      storage_account_type      = lookup(var.settings[each.key].data_disk, "storage_account_type", null)
      disk_size_gb              = lookup(var.settings[each.key].data_disk, "disk_size_gb", null)
      write_accelerator_enabled = lookup(var.settings[each.key].data_disk, "write_accelerator_enabled", null)
      disk_encryption_set_id    = lookup(var.settings[each.key].data_disk, "disk_encryption_set_id", null)
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
      storage_account_uri = lookup(var.settings[each.key].boot_diagnostics, "storage_account_uri", null)
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
    for_each = lookup(var.settings[each.key], "network_interface", {}) != {} ? [1] : []
    content {
      name                          = lookup(var.settings[each.key].network_interface, "name", "nic-${each.key}")
      primary                       = lookup(var.settings[each.key].network_interface, "primary", true)
      network_security_group_id     = lookup(var.settings[each.key].network_interface, "network_security_group_id", null)
      enable_accelerated_networking = lookup(var.settings[each.key].network_interface, "enable_accelerated_networking", null)
      enable_ip_forwarding          = lookup(var.settings[each.key].network_interface, "enable_ip_forwarding", null)
      dns_servers                   = tolist(lookup(var.settings[each.key].network_interface, "dns_servers", null))

      dynamic "ip_configuration" {
        for_each = lookup(var.settings[each.key].network_interface, "ip_configuration", {}) != {} ? [1] : []
        content {
          name                                         = lookup(var.settings[each.key].network_interface.ip_configuration, "name", "nic-ipconfig-${each.key}")
          primary                                      = lookup(var.settings[each.key].network_interface.ip_configuration, "primary", true)
          application_gateway_backend_address_pool_ids = lookup(var.settings[each.key].network_interface.ip_configuration, "application_gateway_backend_address_pool_ids", null)
          application_security_group_ids               = lookup(var.settings[each.key].network_interface.ip_configuration, "application_security_group_ids", toset(azurerm_application_security_group.asg.id))
          load_balancer_backend_address_pool_ids       = lookup(var.settings[each.key].network_interface.ip_configuration, "load_balancer_backend_address_pool_ids", null)
          load_balancer_inbound_nat_rules_ids          = lookup(var.settings[each.key].network_interface.ip_configuration, "load_balancer_inbound_nat_rules_ids", null)
          version                                      = lookup(var.settings[each.key].network_interface.ip_configuration, "version", null)
          subnet_id                                    = lookup(var.settings[each.key].network_interface.ip_configuration, "subnet_id", null)

          dynamic "public_ip_address" {
            for_each = lookup(var.settings[each.key].network_interface.ip_configuration, "public_ip_address", {}) != {} ? [1] : []
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