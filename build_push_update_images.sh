#!/bin/bash
#
# Copyright 2018 Istio Authors
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

set -o errexit

if [ "$#" -ne 2 ]; then
    echo Usage: build-services.sh repository tag
    exit 1
fi

REPOSITORY=$1
TAG=$2

src/build-services.sh $REPOSITORY $TAG
IMAGES=$(docker images -f reference=$REPOSITORY:examples-bookinfo*-$TAG --format "{{.Repository}}:{{.Tag}}")

echo "Following images will be pushed:"
echo "$IMAGES"
for IMAGE in $IMAGES; do docker push $IMAGE; done
