terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {}

# Image Ubuntu
resource "docker_image" "ubuntu" {
  name         = "ubuntu:22.04"
  keep_locally = true
}

# Container Ubuntu แทน EC2
resource "docker_container" "my_ubuntu" {
  image = docker_image.ubuntu.image_id
  name  = "my-ubuntu"
  
  # ทำให้ container รันค้างไว้
  tty   = true
  stdin_open = true
  
  # ต้องเป็น privileged เพื่อให้รัน Docker หรือ k3s ข้างในได้
  privileged = true

  # เปิด port ตามที่เคยเปิดใน Security Group
  ports {
    internal = 22
    external = 2222
  }
  
  ports {
    internal = 3000
    external = 3000
  }
  ports {
    internal = 3001
    external = 3001
  }

  ports {
    internal = 80
    external = 8080
  }

  ports {
    internal = 6443
    external = 6443
  }
}