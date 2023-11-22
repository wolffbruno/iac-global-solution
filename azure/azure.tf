resource "azurerm_resource_group" "web" {
  name     = "iac-resource"
  location = "East US"
}

# Create a virtual network
resource "azurerm_virtual_network" "web" {
  name                = "virtualNetworkName"
  address_space       = ["172.0.0.0/16"]
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name
}

# Create a subnet
resource "azurerm_subnet" "web" {
  name                 = "subnetName"
  resource_group_name  = azurerm_resource_group.web.name
  virtual_network_name = azurerm_virtual_network.web.name
  address_prefixes     = ["172.0.2.0/24"]
}

# Create a Network Security Group and rule
resource "azurerm_network_security_group" "web" {
  name                = "networkSecurityGroupName"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name

  security_rule {
    name                       = "HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSG to subnet
resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}

# Public IP address for the Load Balancer
resource "azurerm_public_ip" "web" {
  name                = "publicIPAddressName"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name
  allocation_method   = "Static"
}

# Load Balancer
resource "azurerm_lb" "web" {
  name                = "loadBalancerName"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name

  frontend_ip_configuration {
    name                 = "publicIPAddress"
    public_ip_address_id = azurerm_public_ip.web.id
  }
}

# Load Balancer Backend Address Pool
resource "azurerm_lb_backend_address_pool" "web" {
  loadbalancer_id = azurerm_lb.web.id
  name            = "backendAddressPoolName"
}

# Load Balancer Rule for HTTP Traffic
resource "azurerm_lb_rule" "web" {
  name                           = "HTTP"
  loadbalancer_id                = azurerm_lb.web.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "publicIPAddress"
  probe_id                       = azurerm_lb_probe.web.id
}

# Load Balancer Health Probe for HTTP Traffic
resource "azurerm_lb_probe" "web" {
  name                = "httpProbe"
  loadbalancer_id     = azurerm_lb.web.id
  protocol            = "Http"
  port                = 80
  request_path        = "/"
  interval_in_seconds = 15
  number_of_probes    = 2
}

# Azure Virtual Machine - Instance 1
resource "azurerm_linux_virtual_machine" "web_instance_1" {
  name                  = "webInstance1"
  computer_name         = "hostname1"
  resource_group_name   = azurerm_resource_group.web.name
  location              = azurerm_resource_group.web.location
  size                  = "Standard_B1ls"
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.web_nic_1.id]
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
                #!/bin/bash
                sudo apt-get update
                sudo apt-get install -y apache2
                sudo systemctl start apache2
                sudo systemctl enable apache2
                echo '<h1>Página HTML própria do Bruno Vinícius Wolff</h1>' | sudo tee /var/www/html/index.html
                EOF
  )
}

# Azure Virtual Machine - Instance 2
resource "azurerm_linux_virtual_machine" "web_instance_2" {
  name                  = "webInstance2"
  computer_name         = "hostname2"
  resource_group_name   = azurerm_resource_group.web.name
  location              = azurerm_resource_group.web.location
  size                  = "Standard_B1ls"
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.web_nic_2.id]
  disable_password_authentication = false
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
                  #!/bin/bash
                  sudo apt-get update
                  sudo apt-get install -y apache2
                  sudo systemctl start apache2
                  sudo systemctl enable apache2
                  echo '<h1>Página HTML própria do Bruno Vinícius Wolff</h1>' | sudo tee /var/www/html/index.html
                  EOF
  )

  tags = {
    Name = "web"
  }
}

# Create network interface for the VMs
resource "azurerm_public_ip" "nic_1" {
    name                = "publicIPAddressName2"
    location            = azurerm_resource_group.web.location
    resource_group_name = azurerm_resource_group.web.name
    allocation_method   = "Static"
}
resource "azurerm_network_interface" "web_nic_1" {
  name                = "webNic1"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name

  ip_configuration {
    name                          = "ipConfiguration1"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
  }
}


resource "azurerm_public_ip" "nic_2" {
    name                = "publicIPAddressName2"
    location            = azurerm_resource_group.web.location
    resource_group_name = azurerm_resource_group.web.name
    allocation_method   = "Static"
}

resource "azurerm_network_interface" "web_nic_2" {
    name                = "webNic2"
    location            = azurerm_resource_group.web.location
    resource_group_name = azurerm_resource_group.web.name
    
    ip_configuration {
        name                          = "ipConfiguration2"
        subnet_id                     = azurerm_subnet.web.id
        private_ip_address_allocation = "Dynamic"
    }
}

# Network Interface Back-end Address Pool Association
resource "azurerm_network_interface_backend_address_pool_association" "web_nic1_association" {
  network_interface_id    = azurerm_network_interface.web_nic_1.id
  ip_configuration_name   = "ipConfiguration1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.web.id
}

resource "azurerm_network_interface_backend_address_pool_association" "web_nic2_association" {
    network_interface_id    = azurerm_network_interface.web_nic_2.id
    ip_configuration_name   = "ipConfiguration2"
    backend_address_pool_id = azurerm_lb_backend_address_pool.web.id
}
