data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "windows_server_2025" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2025-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Linux Bastion (SSM Session Manager)
# インバウンドポート不要・キーペア不要。aws ssm start-session で接続する
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion.name

  tags = { Name = "${local.name_prefix}-bastion-linux" }
}

# Windows Bastion (SSM Fleet Manager + Edge ブラウザ)
# インバウンドポート不要・キーペア不要。AWS コンソールの Fleet Manager から接続する
resource "aws_instance" "windows_bastion" {
  ami                    = data.aws_ami.windows_server_2025.id
  instance_type          = var.windows_bastion_instance_type
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.windows_bastion.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion.name

  tags = { Name = "${local.name_prefix}-bastion-windows" }
}
