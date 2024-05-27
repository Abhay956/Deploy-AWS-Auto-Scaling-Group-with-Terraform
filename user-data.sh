#!/bin/bash
sudo apt update -y
sudo apt install -y apache2
sudo systemctl start apache2
sudo systemctl enable apache2

echo "<html><head><title> AWS autoscaling with Terraform </title>
</head>
<body>
<p> site is working :)
</body>
</html>" >/var/www/html/index.html
