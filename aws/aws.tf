// create two ec2 with load balancer attached to them. The ec2s must have a apache server html page

resource "aws_vpc" "web" {
  cidr_block = "172.0.0.0/16"
}

resource "aws_subnet" "web" {
  vpc_id                  = aws_vpc.web.id
  cidr_block              = "172.0.2.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "web" {
  vpc_id = aws_vpc.web.id
}

resource "aws_route_table" "web" {
  vpc_id = aws_vpc.web.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.web.id
  }
}

resource "aws_route_table_association" "web" {
  subnet_id      = aws_subnet.web.id
  route_table_id = aws_route_table.web.id
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.web.id

  ingress {
    description = "HTTP"
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

resource "aws_instance" "web_instance_1" {
  ami                         = "ami-0230bd60aa48260c6"
  instance_type               = "t2.micro"
  availability_zone           = "us-east-1a"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.web.id
  vpc_security_group_ids      = [aws_security_group.web.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo '<h1>Página HTML própria do Bruno Vinícius Wolff</h1>' | tee /var/www/html/index.html
              EOF

  tags = {
    Name = "web"
  }
}

resource "aws_instance" "web_instance_2" {
  ami                         = "ami-0230bd60aa48260c6"
  instance_type               = "t2.micro"
  availability_zone           = "us-east-1a"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.web.id
  vpc_security_group_ids      = [aws_security_group.web.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo '<h1>Página HTML própria do Bruno Vinícius Wolff</h1>' | tee /var/www/html/index.html
              EOF

  tags = {
    Name = "web"
  }
}

resource "aws_elb" "web" {
  name            = "web"
  security_groups = [aws_security_group.web.id]
  instances       = [aws_instance.web_instance_1.id, aws_instance.web_instance_2.id]
  subnets         = [aws_subnet.web.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}
