variable "VERSION" {
  default = "dev"
}

target "default" {
  context    = "."
  dockerfile = "Dockerfile"
  platforms  = ["linux/amd64", "linux/arm64"]
  args = {
    VERSION = VERSION
  }
  tags = ["docker-workflow-test:${VERSION}"]
}
