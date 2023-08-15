resource "aws_vpc" "zer0vpc" {
  cidr_block = "10.123.0.0/16"

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "zer0_Public_subnet" {
  vpc_id                  = aws_vpc.zer0vpc.id
  cidr_block              = "10.123.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "dev_public"
  }
}

resource "aws_internet_gateway" "zer0_internet_gateway" {
  vpc_id = aws_vpc.zer0vpc.id

  tags = {
    Name = "dev_IGW"
  }
}

resource "aws_route_table" "zer0_public_rt" {
  vpc_id = aws_vpc.zer0vpc.id

  tags = {
    Name = "dev_public_rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.zer0_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.zer0_internet_gateway.id
}

resource "aws_route_table_association" "zer0_public_rta" {
  subnet_id      = aws_subnet.zer0_Public_subnet.id
  route_table_id = aws_route_table.zer0_public_rt.id
}

resource "aws_subnet" "zer0_Private_subnet" {
  vpc_id            = aws_vpc.zer0vpc.id
  cidr_block        = "10.123.2.0/24"
  availability_zone = "us-east-1a"


  tags = {
    Name = "dev_private"
  }
}

resource "aws_eip" "nat_gw_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "zer0_nat_gw" {
  allocation_id = aws_eip.nat_gw_eip.id
  subnet_id     = aws_subnet.zer0_Private_subnet.id

  tags = {
    Name = "dev_nat"
  }

  depends_on = [aws_internet_gateway.zer0_internet_gateway]
}

resource "aws_route_table" "zer0_private_rt" {
  vpc_id = aws_vpc.zer0vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.zer0_nat_gw.id
  }

  tags = {
    Name = "private_rt"
  }
}

resource "aws_route_table_association" "zer0_private_rta" {
  subnet_id      = aws_subnet.zer0_Private_subnet.id
  route_table_id = aws_route_table.zer0_private_rt.id
}

resource "aws_security_group" "zer0_alb_sg" {
  name        = "zer0_alb_sg"
  description = "Security group for the ALB"
  vpc_id      = aws_vpc.zer0vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "zer0_auth" {
  key_name   = "zer0key"
  public_key = file("~/.ssh/zer0key.pub")
}

resource "aws_lb" "zer0_alb" {
  name               = "zer0-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.zer0_alb_sg.id]
  subnets            = [aws_subnet.zer0_Public_subnet.id]

  enable_deletion_protection = false

  enable_http2 = true

  enable_cross_zone_load_balancing = true

  idle_timeout = 400

  access_logs {
    bucket  = "zer0-alb-logs"
    prefix  = "alb/"
    enabled = true
  }

  tags = {
    Name = "dev_alb"
  }
}

resource "aws_lb_target_group" "zer0_target_group" {
  name     = "zer0-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.zer0vpc.id

  health_check {
    path = "/health"
    port = "traffic-port"
  }

  tags = {
    Name = "dev_target_group"
  }
}

resource "aws_lb_listener" "zer0_listener" {
  load_balancer_arn = aws_lb.zer0_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.zer0_target_group.arn
  }
}

resource "aws_autoscaling_group" "zer0_asg" {
  name                 = "zer0-asg"
  max_size             = 1
  min_size             = 1
  desired_capacity     = 1
  health_check_type    = "ELB"
  launch_configuration = aws_launch_configuration.zer0_lc.name
  vpc_zone_identifier  = [aws_subnet.zer0_Private_subnet.id]
  force_delete         = true
}

resource "aws_launch_configuration" "zer0_lc" {
  name_prefix     = "zer0-lc"
  image_id        = data.aws_ami.server_ami.id
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.zer0_auth.key_name
  security_groups = [aws_security_group.zer0_alb_sg.id]
  user_data       = file("userdata.tpl")

  root_block_device {
    volume_size = 8
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_key_pair.zer0_auth]
}

