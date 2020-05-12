#!/bin/bash

set -e

version="14-1.0.1"

thisDir=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)

${thisDir}/base/build.sh "${version}"
${thisDir}/onbuild/build.sh "${version}"
${thisDir}/builder/build.sh "${version}"
