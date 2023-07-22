provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "var.RG-name"
  location = "var.location"
}

# Web Tier - Azure App Service
resource "azurerm_app_service_plan" "web" {
  name                = "var.appserviceplan"
  location            = "var.location"
  resource_group_name = "var.RG-name"
  kind                = "var.kind"
  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "web" {
  name                = "web-app"
  location            = var.location
  resource_group_name = var.Rgname
  app_service_plan_id = azurerm_app_service_plan.web.id
}

# Application Tier - Azure Virtual Machine
resource "azurerm_virtual_network" "app" {
  name                = "var.virtual network"
  address_space       = ["10.0.0.0/16"]
  location            = "var.location"
  resource_group_name = "var.Rgname"
}

resource "azurerm_subnet" "app" {
  name                 = "var.subnet"
  resource_group_name  = var.Rgname
  virtual_network_name = "var.virtual network"
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_network_interface" "app" {
  name                = "app-nic"
  location            = var.location
  resource_group_name = var.Rgname

  ip_configuration {
    name                          = "app-ipconfig"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "app" {
  name                  = "var.virtual machine"
  location              = var.location
  resource_group_name   = var.RG-name
  network_interface_ids = [azurerm_network_interface.app.id]

  vm_size              = "General purpose d2sv5"
  delete_os_disk_on_termination = true

  storage_image_reference {
    offer     = "WindowsServer"
    sku       = "2022 datacenter"
    version   = "latest"
  }

  os_profile {
    computer_name  = "app-vm"
    admin_username = "adminuser"
    admin_password = "AdminPassw0rd!"  # Replace with your desired password
  }

  os_disk {
    name              = "app-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
}

# Database Tier - Azure SQL Database
resource "azurerm_sql_server" "db" {
  name                         = "db-server"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "SqlAdm1nP@ss!"  # Replace with your desired password
}

resource "azurerm_sql_database" "db" {
  name                = "app-database"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  server_name         = azurerm_sql_server.db.name
  requested_service_objective_name = "S0"  # Basic performance level
}

