resource "azurerm_linux_virtual_machine_scale_set" "linux_vm_scale_set" {

  // Forces acceptance of marketplace terms before creating a VM
  depends_on = [
    azurerm_marketplace_agreement.plan_acceptance_simple,
    azurerm_marketplace_agreement.plan_acceptance_custom
  ]

  name                 = "${var.vm_hostname}${format("%02d", count.index + 1)}"
  resource_group_name  = var.rg_name
  location             = var.location
  computer_name_prefix = var.computer_name_prefix
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  edge_zone            = var.edge_zone
  instances            = var.instances
  sku                  = var.vm_size
  priority             = var.spot_instance ? "Spot" : "Regular"
  max_bid_price        = var.spot_instance ? var.spot_instance_max_bid_price : null
  eviction_policy      = var.spot_instance ? var.spot_instance_eviction_policy : null

  dynamic "additional_capabilities" {
    for_each = lookup(var.settings, "additional_capabilities", {}) != {} ? [1] : []
    content {
      ultra_ssd_enabled = lookup(var.settings.additional_capabilities, "ultra_ssd_enabled", false)
    }
  }

  dynamic "automatic_os_upgrade_policy" {
    for_each = lookup(var.settings, "automatic_os_upgrade_policy", {}) != {} ? [1] : []
    content {

      disable_automatic_rollback  = lookup(var.settings.automatic_os_upgrade_policy, "disable_automatic_rollback", false)
      enable_automatic_os_upgrade = lookup(var.settings.automatic_os_upgrade_policy, "enable_automatic_os_upgrade", true)
    }
  }

  dynamic "automatic_instance_repair" {
    for_each = lookup(var.settings, "automatic_instance_repair", {}) != {} ? [1] : []
    content {

      enabled  = lookup(var.settings.automatic_instance_repair, "enabled", true)
      grace_period = lookup(var.settings.automatic_instance_repair, "grace_period", null)
    }
  }



  dynamic "network_interface" {
    for_each = lookup(var.settings, "network_interface", {}) != {} ? [1] : []
    content {
      name                          = lookup(var.settings.network_interface, "name", null)
      primary                       = lookup(var.settings.network_interface, "primary", null)
      network_security_group_id     = lookup(var.settings.network_interface, "network_security_group_id", null)
      enable_accelerated_networking = lookup(var.settings.network_interface, "enable_accelerated_networking", null)
      enable_ip_forwarding          = lookup(var.settings.network_interface, "enable_ip_forwarding", null)
      dns_servers                   = tolist(lookup(var.settings.network_interface, "dns_servers", null))

      dynamic "ip_configuration" {
        for_each = lookup(var.settings.network_interface, "ip_configuration", {}) != {} ? [1] : []
        content {
          name                                         = lookup(var.settings.network_interface.ip_configuration, "name", null)
          primary                                      = lookup(var.settings.network_interface.ip_configuration, "primary", null)
          application_gateway_backend_address_pool_ids = lookup(var.settings.network_interface.ip_configuration, "application_gateway_backend_address_pool_ids", null)
          application_security_group_ids               = lookup(var.settings.network_interface.ip_configuration, "application_security_group_ids", null)
          load_balancer_backend_address_pool_ids       = lookup(var.settings.network_interface.ip_configuration, "load_balancer_backend_address_pool_ids", null)
          load_balancer_inbound_nat_rules_ids          = lookup(var.settings.network_interface.ip_configuration, "load_balancer_inbound_nat_rules_ids", null)
          version                                      = lookup(var.settings.network_interface.ip_configuration, "version", null)
          subnet_id                                    = lookup(var.settings.network_interface.ip_configuration, "subnet_id", null)

          dynamic "public_ip_address" {
            for_each = lookup(var.settings.network_interface.ip_configuration, "public_ip_address", {}) != {} ? [1] : []
            content {
              name                    = lookup(var.settings.network_interface.ip_configuration.public_ip_address, "name", null)
              domain_name_label       = lookup(var.settings.network_interface.ip_configuration.public_ip_address, "domain_name_label", null)
              idle_timeout_in_minutes = lookup(var.settings.network_interface.ip_configuration.public_ip_address, "idle_timeout_in_minutes", null)
              public_ip_prefix_id     = lookup(var.settings.network_interface.ip_configuration.public_ip_address, "public_ip_prefix_id ", null)

              dynamic "ip_tag" {
                for_each = lookup(var.settings.network_interface.ip_configuration.public_ip_address, "public_ip_address", {}) != {} ? [1] : []
                content {
                  type = lookup(var.settings.network_interface.ip_configuration.public_ip_address.ip_tag, "type", null)
                  tag  = lookup(var.settings.network_interface.ip_configuration.public_ip_address.ip_tag, "tag", null)
                }
              }
            }
          }
        }
      }
    }
  }


  #checkov:skip=CKV_AZURE_151:Ensure Encryption at host is enabled
  encryption_at_host_enabled = var.enable_encryption_at_host

  #checkov:skip=CKV_AZURE_50:Ensure Virtual Machine extensions are not installed
  provision_vm_agent = var.provision_vm_agent

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

  os_disk {
    name                 = "osdisk-${var.vm_hostname}"
    caching              = "ReadWrite"
    storage_account_type = var.storage_account_type
    disk_size_gb         = var.vm_os_disk_size_gb
    disk_iops_read_write = try(var.disk_iops_read_write, null)
    disk_mbps_read_write = try(var.disk_mbps_read_write, null)

    write_accelerator_enabled = var.write_accelerator_enabled

    diff_disk_settings {
      option = try(var.diff_disk_setting_option, null)
    }
  }

  boot_diagnostics {
    storage_account_uri = null // Use managed storage account
  }

  tags = var.tags
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