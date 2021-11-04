variable REGION {
  default = "ap-south-1"
}

variable ZONE1 {
  default = "ap-south-1a"
}

variable AMIS {
  type = map
  default = {
    us-east-2 = "ami-0c1a7f89451184c8b"
    ap-south-1 = "ami-0c1a7f89451184c8b"
  }
}