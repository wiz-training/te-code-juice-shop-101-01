# One public EC2 running the annotated image; the grader applies this with local state.
variable "image" { type = string }
variable "name" { type = string }
variable "region" { type = string }

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

# The lease account has no default VPC.
resource "aws_vpc" "lab" {
  cidr_block = "10.42.0.0/16"
  tags       = { Name = var.name }
}

resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.42.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web" {
  name   = "${var.name}-web"
  vpc_id = aws_vpc.lab.id
  ingress {
    from_port   = 3000
    to_port     = 3000
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

resource "aws_iam_role" "pull" {
  name               = "${var.name}-pull"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Action = "sts:AssumeRole", Principal = { Service = "ec2.amazonaws.com" } }] })
}

resource "aws_iam_role_policy_attachment" "pull" {
  role       = aws_iam_role.pull.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "pull" {
  name = "${var.name}-pull"
  role = aws_iam_role.pull.name
}

resource "aws_instance" "app" {
  iam_instance_profile        = aws_iam_instance_profile.pull.name
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.small"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  tags                        = { Name = var.name }
  user_data                   = <<-EOT
    #!/bin/bash
    dnf install -y docker && systemctl enable --now docker
    aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${split("/", var.image)[0]}
    docker run -d --restart always -p 3000:3000 ${var.image}
  EOT
}

output "public_ip" { value = aws_instance.app.public_ip }
