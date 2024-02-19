group "default" {
  targets = [ "mssql" ]
}

variable "BASE_IMAGE_NAME" {
    default = "localhost:5000/kcollins/mssql"
}

target "global" {
  platforms = [ "linux/amd64" ]
  contexts = {
    shared = "shared"
  }
  attest = [
    "type=provenance,mode=min",
    "type=sbom"
  ]
}

target "mssql" {
  name = "mssql-${major}"
  context = "shared"
  dockerfile = "../Dockerfile"
  inherits = [ "global" ]
  matrix = {
    major = [ "2017", "2019", "2022" ]
  }
  args = {
    MSSQL_UPSTREAM_TAG = "${major}-latest"
  }
  cache-to = ["type=registry,ref=${BASE_IMAGE_NAME}:cache-${major}"]
  cache-from = ["type=registry,ref=${BASE_IMAGE_NAME}:cache-${major}"]
  tags = [
    "${BASE_IMAGE_NAME}:${major}",
    "${BASE_IMAGE_NAME}:${major}-latest",
    "${major}" == "2022" ? "${BASE_IMAGE_NAME}:latest" : "",
  ]
}