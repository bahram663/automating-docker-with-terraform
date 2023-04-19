terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}
resource "null_resource" "dockervol" {
  provisioner "local-exec" {
    command = "mkdir noderedvol/ || true && chown -R 1000:1000 noderedvol/"
  }
}

resource "docker_image" "nodered_image" {
  name = var.image[terraform.workspace]
}

resource "random_string" "random" {
  count   = local.container_count
  length  = 4
  special = false
}

# Create a container
resource "docker_container" "nodered_container" {
  count = local.container_count
  image = docker_image.nodered_image.image_id
  name  = join("-", ["nodered", terraform.workspace, random_string.random[count.index].result])
  ports {
    internal = var.int_port
    external = var.ext_port[terraform.workspace][count.index]
  }
  volumes {
    container_path = "/data"
    host_path      = "${path.cwd}/noderedvol"
  }
}