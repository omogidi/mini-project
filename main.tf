provider "aws" {
  region = "us-east-1"
}

# Create VPC
resource "aws_vpc" "mini-projectVPC" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "mini-projectVPC"
  }
}

# Create Internet Gateway

resource "aws_internet_gateway" "miniProject-IGW" {
  vpc_id = aws_vpc.mini-projectVPC.id
  tags = {
    Name = "mini-IGW"
  }
}

# Create Route Table

resource "aws_route_table" "mini-RT" {
  vpc_id = aws_vpc.mini-projectVPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.miniProject-IGW.id
  }
  tags = {
    Name = "mini-public-RT"
  }
}

# Create Public Subnet1

resource "aws_subnet" "mini-publicsubnet1" {
  vpc_id                  = aws_vpc.mini-projectVPC.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "mini-public-subnet1"
  }
}
# Create Public Subnet2
resource "aws_subnet" "mini-publicsubnet2" {
  vpc_id                  = aws_vpc.mini-projectVPC.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
  tags = {
    Name = "mini-public-subnet2"
  }
}

# Associate public subnet 1 with public route table

resource "aws_route_table_association" "mini-public-subnet1-association" {
  subnet_id      = aws_subnet.mini-publicsubnet1.id
  route_table_id = aws_route_table.mini-RT.id
}

# Associate public subnet 2 with public route table

resource "aws_route_table_association" "mini-public-subnet2-association" {
  subnet_id      = aws_subnet.mini-publicsubnet2.id
  route_table_id = aws_route_table.mini-RT.id
}

resource "aws_network_acl" "mini-networkACL" {
  vpc_id     = aws_vpc.mini-projectVPC.id
  subnet_ids = [aws_subnet.mini-publicsubnet1.id, aws_subnet.mini-publicsubnet2.id]

  ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

# Create Security Group

resource "aws_security_group" "mini-LB-SG" {
  name        = "mini-LB-SG"
  description = "Security group for the load balancer"
  vpc_id      = aws_vpc.mini-projectVPC.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create SG for EC2 instances

resource "aws_security_group" "mini-EC2-SG" {
  name        = "allow_ssh_http_https"
  description = "Allow SSH, HTTP and HTTPS inbound traffic for private instances"
  vpc_id      = aws_vpc.mini-projectVPC.id
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description     = "HTTP"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.mini-LB-SG.id]
  }
  ingress {
    description     = "HTTPS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.mini-LB-SG.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "mini-EC2-SG"
  }
}
# Create Server 1

resource "aws_instance" "mini-server1" {
  ami               = "ami-00874d747dde814fa"
  instance_type     = "t2.micro"
  key_name          = "tempkey"
  security_groups   = [aws_security_group.mini-EC2-SG.id]
  subnet_id         = aws_subnet.mini-publicsubnet1.id
  availability_zone = "us-east-1a"
  tags = {
    Name   = "Server1"
    source = "terraform"
  }
}

# Creating Server 2

resource "aws_instance" "mini-server2" {
  ami               = "ami-00874d747dde814fa"
  instance_type     = "t2.micro"
  key_name          = "tempkey"
  security_groups   = [aws_security_group.mini-EC2-SG.id]
  subnet_id         = aws_subnet.mini-publicsubnet2.id
  availability_zone = "us-east-1b"
  tags = {
    Name   = "Server2"
    source = "terraform"
  }
}
# Creating Server 3

resource "aws_instance" "mini-server3" {
  ami               = "ami-00874d747dde814fa"
  instance_type     = "t2.micro"
  key_name          = "tempkey"
  security_groups   = [aws_security_group.mini-EC2-SG.id]
  subnet_id         = aws_subnet.mini-publicsubnet1.id
  availability_zone = "us-east-1a"
  tags = {
    Name   = "Server3"
    source = "terraform"
  }
}

# Create a file to store the IP addresses of the instances

resource "local_file" "Ip_address" {
  filename = "/mini-project/host-inventory"
  content  = <<EOT
${aws_instance.mini-server1.public_ip}
${aws_instance.mini-server2.public_ip}
${aws_instance.mini-server3.public_ip}
  EOT
}



resource "aws_lb" "mini-LB" {
  name               = "mini-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.mini-LB-SG.id]
  subnets            = [aws_subnet.mini-publicsubnet1.id, aws_subnet.mini-publicsubnet2.id]
  tags = {
    Name = "mini-LB"
  }

  # enable_cross_zone_load_balancing = true
  enable_deletion_protection = false
  depends_on                 = [aws_instance.mini-server1, aws_instance.mini-server2, aws_instance.mini-server3]
}

#Target Group

resource "aws_lb_target_group" "mini-TG" {
  name        = "mini-TG"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.mini-projectVPC.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

# Listener

resource "aws_lb_listener" "mini-listener" {
  load_balancer_arn = aws_lb.mini-LB.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mini-TG.arn
  }
}

# Create the listener rule

resource "aws_lb_listener_rule" "mini-listener-rule" {
  listener_arn = aws_lb_listener.mini-listener.arn
  priority     = 1
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mini-TG.arn
  }
  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

resource "aws_lb_target_group_attachment" "mini-TG-attachment1" {
  target_group_arn = aws_lb_target_group.mini-TG.arn
  target_id        = aws_instance.mini-server1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "mini-TG-attachment2" {
  target_group_arn = aws_lb_target_group.mini-TG.arn
  target_id        = aws_instance.mini-server2.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "mini-TG-attachment3" {
  target_group_arn = aws_lb_target_group.mini-TG.arn
  target_id        = aws_instance.mini-server3.id
  port             = 80
}

# provisioner "local-exec" {
#     when = "create"
#     command = "ansible-playbook -i host-inventory playbook.yml"

# }