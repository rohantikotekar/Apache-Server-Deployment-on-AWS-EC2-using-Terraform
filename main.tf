
provider "aws" {
  region = "us-east-1"
  access_key = "AKIA5Y72SABUUJSMP5UJ"
  secret_key = "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"
}

resource "aws_vpc" "prod_vpc" {
  cidr_block = "10.0.0.0/16"

  
  tags = {
    Name = "production"
  }
  

 
}

resource "aws_subnet" "subnet_1" {


  vpc_id     = aws_vpc.prod_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

   tags = {
    Name = "prod_subnet"
  }

  
}


resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod_vpc.id

}


resource "aws_route_table" "prod_route_table" {
  vpc_id = aws_vpc.prod_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id =  aws_internet_gateway.gw.id
  }

  tags = {
    Name = "prod"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.prod_route_table.id
}


resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.prod_vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

   ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }



  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg"
  }
}


resource "aws_instance" "web-server-instance" {
  ami = "ami-007855ac798b5175e"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "keyterraform"
  subnet_id       = aws_subnet.subnet_1.id


  user_data =  <<EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo your first server > /var/www/html/index.html'
              EOF

  tags = {
    Name = "inst"
  }
}




resource "aws_network_interface" "web_server_nic" {
  subnet_id       = aws_subnet.subnet_1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

  attachment {
    instance     = aws_instance.web-server-instance.id
    device_index = 1
  }
}


resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web_server_nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [    aws_internet_gateway.gw
]


  
}

  

/* resource "aws_instance" "foo" {
  ami           = "ami-007855ac798b5175e"
  instance_type = "t2.micro"
   tags = {
    Name = "ubuntuu"
  }

  
}*/


