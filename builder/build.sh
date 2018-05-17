#!/bin/bash

cd $(dirname $(realpath ${BASH_SOURCE[0]}))
set -e

base="towerhawk/alpine-java-builder"
version=$1
build_tag="$base:$version"

docker build -t "$build_tag" \
  --pull \
  --squash \
  .

docker tag "$build_tag" "$base:latest"
