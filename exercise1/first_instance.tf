provider "aws" {
  region = "ap-south-1"
  #   access_key = ""
  #   secret_key = ""	
}

resource "aws_instance" "intro" {
  ami                    = "ami-0c1a7f89451184c8b"
  instance_type          = "t2.micro"
  availability_zone      = "ap-south-1a"
  key_name               = "kubernetes_mumbai"
  vpc_security_group_ids = ["sg-0628ad93a7b58f5f5"]
  tags = {
    Name    = "Dove-Instance"
    Project = "Dove"
  }
}
