#!/bin/bash

version="8-1.2.4"

base/build.sh "${version}"
onbuild/build.sh "${version}"
builder/build.sh "${version}"
