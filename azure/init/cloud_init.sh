#!/bin/bash
    
echo "Update with latest packages"
sudo apt update
    
echo "Install Apache"
sudo apt install apache2 git -y

echo "<html><body><h1>Página HTML própria do Bruno Vinícius Wolff, na Azure</h1></body></html>" | sudo tee /var/www/html/index.html