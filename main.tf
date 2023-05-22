provider "aws" {
  region = "us-east-1"
}

variable "network_ips" {
  description = "IPs range for vpc and subnet, and web server instance IP"
  type = object({
    vpc_cidr_prefix = string,
    subnet_cidr_prefix = string,
    instance_private_ip = string
  })

  default = {
    vpc_cidr_prefix = "10.0.0.0/16",
    subnet_cidr_prefix = "10.0.1.0/24"
    instance_private_ip = "10.0.1.50"
  }
}

resource "aws_key_pair" "web_server_keypair" {
  key_name   = "web-server-keypair"
  public_key = "TODO: SET PUBLIC KEY"
}

resource "aws_vpc" "web_vpc" {
  cidr_block = var.network_ips.vpc_cidr_prefix

  tags = {
    Name = "Web VPC"
  }
}

resource "aws_internet_gateway" "web_gw" {
  vpc_id = aws_vpc.web_vpc.id

  tags = {
    Name = "Web Gateway"
  }
}

resource "aws_route_table" "web_rt" {
  vpc_id = aws_vpc.web_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.web_gw.id
  }

  tags = {
    Name = "Web Route Table"
  }
}

resource "aws_subnet" "web_subnet" {
  vpc_id     = aws_vpc.web_vpc.id
  cidr_block = var.network_ips.subnet_cidr_prefix

  tags = {
    Name = "Web Subnet"
  }
}

resource "aws_route_table_association" "web_rt_association" {
  subnet_id      = aws_subnet.web_subnet.id
  route_table_id = aws_route_table.web_rt.id
}

resource "aws_security_group" "web_sg" {
  name        = "Web SG"
  description = "Allow Web Traffic"
  vpc_id      = aws_vpc.web_vpc.id

  ingress {
    description = "HTTPS Traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP Traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH Traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web SG"
  }
}

resource "aws_network_interface" "web_nic" {
  subnet_id       = aws_subnet.web_subnet.id
  private_ips     = [var.network_ips.instance_private_ip]
  security_groups = [aws_security_group.web_sg.id]
}

resource "aws_eip" "web_eip" {
  vpc                       = true
  associate_with_private_ip = var.network_ips.instance_private_ip
  network_interface         = aws_network_interface.web_nic.id

  depends_on = [aws_internet_gateway.web_gw]
}

resource "aws_instance" "web_server" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  #   key_name      = "terraform-web-keypair"
  key_name = aws_key_pair.web_server_keypair.key_name



  network_interface {
    network_interface_id = aws_network_interface.web_nic.id
    device_index         = 0
  }

  # Install apache2
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo "Cristobals web server" > /var/www/html/index.html'
                EOF

  tags = {
    Name = "Web Server"
  }
}

output "web_server_public_ip" {
  value = aws_instance.web_server.public_ip
}
