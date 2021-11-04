resource "aws_instance" "dove-inst" {
  ami                    = var.AMIS[var.REGION]
  instance_type          = "t2.micro"
  availability_zone      = var.ZONE1
  key_name               = "kubernetes_mumbai"
  vpc_security_group_ids = ["sg-0628ad93a7b58f5f5"]
  tags = {
    Name    = "Dove-Instance_terraform2"
    Project = "Dove"
  }
}
