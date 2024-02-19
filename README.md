# MSSQL for Linux under Docker with Extras 😎

[![Docker Stars](https://img.shields.io/docker/stars/kcollins/mssql.svg)](https://hub.docker.com/r/kcollins/mssql)
[![Docker Pulls](https://img.shields.io/docker/pulls/kcollins/mssql.svg)](https://hub.docker.com/r/kcollins/mssql)

This is the Git repository for the [kcollins/mssql](http://hub.docker.com/r/kcollins/mssql) Docker Hub image.  It includes a `docker-compose.yml` file for easy use within a Docker Compose or Swarm configuration.  See the [Docker Hub page](http://hub.docker.com/r/kcollins/mssql) for more information on how to use this image.

The full README documentation from the Docker Hub page is maintained in the [docs](docs) folder in the event that you would like to submit additions or corrections to the usage guidance.

## Building this solution

To build the images and load (`--load`) to your local Docker Engine, use the following:

```bash
# Produces images:
# - localhost:5000/kcollins/mssql:2017
# - localhost:5000/kcollins/mssql:2019
# - localhost:5000/kcollins/mssql:2022
docker buildx bake --load --provenance=false --sbom=false
```

For more information, see [High-level builds with Bake](https://docs.docker.com/build/bake/).
