#!/bin/bash

cd $(dirname $(realpath ${BASH_SOURCE[0]}))

set -e

base="towerhawk/alpine-java-onbuild"
version="$1"
build_tag="$base:$version"

docker build $2 -t "$build_tag" .