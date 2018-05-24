#!/bin/bash

version="8-1.2.3"

base/build.sh "${version}"
onbuild/build.sh "${version}"
builder/build.sh "${version}"
