variable "admin_password" {
  description = "The admin password to be used on the VMSS that will be deployed. The password must meet the complexity requirements of Azure."
  type        = string
  default     = ""
}

variable "admin_username" {
  description = "The admin username of the VM that will be deployed."
  type        = string
  default     = "LibreDevOpsAdmin"
}

variable "asg_name" {
  type        = string
  description = "Name of the application security group"
}

variable "identity_ids" {
  description = "Specifies a list of user managed identity ids to be assigned to the VM."
  type        = list(string)
  default     = []
}

variable "identity_type" {
  description = "The Managed Service Identity Type of this Virtual Machine."
  type        = string
  default     = ""
}

variable "location" {
  description = "The location for this resource to be put in"
  type        = string
}

variable "plan" {
  description = "When a plan VM is used with a image not in the calculator, this will contain the variables used"
  type        = map(any)
  default     = {}
}

variable "rg_name" {
  description = "The name of the resource group, this module does not create a resource group, it is expecting the value of a resource group already exists"
  type        = string
  validation {
    condition     = length(var.rg_name) > 1 && length(var.rg_name) <= 24
    error_message = "Resource group name is not valid."
  }
}

variable "settings" {
  type        = any
  description = "Used for the settings block"
}

variable "source_image_reference" {
  default     = {}
  description = "Whether the module should use the a custom image"
  type        = map(any)
}

variable "ssh_public_key" {
  description = "The public key to be added to the admin username"
  type        = string
}

variable "tags" {
  type        = map(string)
  description = "A map of the tags to use on the resources that are deployed with this module."

  default = {
    source = "terraform"
  }
}

variable "use_simple_image" {
  default     = true
  description = "Whether the module should use the simple OS calculator module, default is true"
  type        = bool
}

variable "use_simple_image_with_plan" {
  default     = false
  description = "If you are using the Windows OS Sku Calculator with plan, set this to true. Default is false"
  type        = bool
}

variable "vm_os_id" {
  description = "The resource ID of the image that you want to deploy if you are using a custom image.Note, need to provide is_windows_image = true for windows custom images."
  type        = string
  default     = ""
}

variable "vm_os_offer" {
  description = "The name of the offer of the image that you want to deploy. This is ignored when vm_os_id or vm_os_simple are provided."
  type        = string
  default     = ""
}

variable "vm_os_publisher" {
  description = "The name of the publisher of the image that you want to deploy. This is ignored when vm_os_id or vm_os_simple are provided."
  type        = string
  default     = ""
}

variable "vm_os_simple" {
  description = "Specify WindowsServer, to get the latest image version of the specified os.  Do not provide this value if a custom value is used for vm_os_publisher, vm_os_offer, and vm_os_sku."
  type        = string
  default     = ""
}

variable "vm_os_sku" {
  description = "The sku of the image that you want to deploy. This is ignored when vm_os_id or vm_os_simple are provided."
  type        = string
  default     = ""
}

variable "vm_os_version" {
  description = "The version of the image that you want to deploy. This is ignored when vm_os_id or vm_os_simple are provided."
  type        = string
  default     = "latest"
}

variable "vm_plan" {
  description = "Used for VMs which requires a plan"
  type        = set(string)
  default     = null
}

variable "vm_size" {
  description = "Specifies the size of the virtual machine."
  type        = string
  default     = "Standard_B2ms"
}
