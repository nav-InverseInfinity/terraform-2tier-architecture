#!/bin/bash

sudo yum update -y
sudo yum install -y httpd
sudo echo "<h> Hello from $(hostname)</h>" > /var/www/html/index.html
sudo systemctl start httpd && sudo systemctl enable httpd
