#!/bin/bash

version="8-1.1.0"

base/build.sh "${version}"
onbuild/build.sh "${version}"
builder/build.sh "${version}"
