resource "docker_registry_image" "image" {
  name = "${var.registry_url}/${var.username}/terraform-docker-provider-dockerignore:latest"

  build {
    context = dirname(abspath(path.module))
    labels = {
      "org.opencontainers.image.source" = "https://github.com/${var.username}/terraform-docker-provider-dockerignore"
    }
  }
}
