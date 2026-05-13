output "container_name" {
  value = docker_container.my_ubuntu.name
}

output "container_ports" {
  value = docker_container.my_ubuntu.ports
}