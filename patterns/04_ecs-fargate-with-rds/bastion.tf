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

data "aws_ami" "windows_server_2022" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "windows_server_2016" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2016-English-Full-Base-*"]
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

# Windows Bastion 1 - Windows Server 2022
# インバウンドポート不要・キーペア不要。AWS コンソールの Fleet Manager から接続する
resource "aws_instance" "windows_bastion_1" {
  ami                    = data.aws_ami.windows_server_2022.id
  instance_type          = var.windows_bastion_instance_type
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.windows_bastion.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion.name

  tags = { Name = "${local.name_prefix}-bastion-windows-1" }
}

# Windows Bastion 2 - Windows Server 2016
# インバウンドポート不要・キーペア不要。AWS コンソールの Fleet Manager から接続する
# カスタム AMI から起動する場合、SSM Agent に元インスタンスの登録情報が残るため
# 起動時にクリアして再登録させる
resource "aws_instance" "windows_bastion_2" {
  ami                    = data.aws_ami.windows_server_2016.id
  instance_type          = var.windows_bastion_instance_type
  subnet_id              = aws_subnet.private[1].id
  vpc_security_group_ids = [aws_security_group.windows_bastion.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion.name

  user_data = <<-EOF
    <powershell>
    Stop-Service AmazonSSMAgent -Force
    Remove-Item "C:\ProgramData\Amazon\SSM\InstanceData\*" -Recurse -Force
    Start-Service AmazonSSMAgent
    </powershell>
  EOF

  tags = { Name = "${local.name_prefix}-bastion-windows-2" }
}
