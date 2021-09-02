provider "docker" {
  registry_auth {
    address  = var.registry_url
    username = var.username
    password = var.github_access_token
  }
}
