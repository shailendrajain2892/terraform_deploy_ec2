
# Create VPC
resource "aws_vpc" "learning" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}

# Create Public Subnet
resource "aws_subnet" "pubcliSubnet1" {
  vpc_id     = aws_vpc.learning.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "pubcliSubnet1"
  }
}
# resource "aws_subnet" "pubcliSubnet2" {
#   vpc_id     = aws_vpc.learning.id
#   cidr_block = "10.0.2.0/24"

#   tags = {
#     Name = "pubcliSubnet2"
#   }
# }
# Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.learning.id

  tags = {
    Name = "ConnectToInternet"
  }
}

# Creaet Route table 
resource "aws_route_table" "publicroutetable" {
  vpc_id = aws_vpc.learning.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "RouteTableToPublicSubnetInternte"
  }
}

# Associate subnet with route table
resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.pubcliSubnet1.id
  route_table_id = aws_route_table.publicroutetable.id
}
# resource "aws_route_table_association" "rta2" {
#   subnet_id      = aws_subnet.pubcliSubnet2.id
#   route_table_id = aws_route_table.publicroutetable.id
# }
# create ec2 instance in each public Subnet

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "SGPublic" {
  name   = "security_group_public"
  vpc_id = aws_vpc.learning.id
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "80 from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "web" {
  ami                         = "ami-0a699202e5027c10d" # amazon linux2 ami
  instance_type               = "t2.micro"
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.SGPublic.id]
  subnet_id                   = aws_subnet.pubcliSubnet1.id
  associate_public_ip_address = true

  user_data = <<EOF
  #!/bin/bash
    sudo yum update -y
    sudo amazon-linux-extras install nginx1
    sudo systemctl start nginx
    sudo systemctl enable nginx
    sudo systemctl status nginx
    echo fin v1.00!
    EOF
  tags = {
    Name = "Terraform"
  }
}
