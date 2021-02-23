#!/bin/bash

LABEL=${1:-}

find /backups/*${LABEL} | sort | tail -n 1
