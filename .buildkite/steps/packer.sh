#!/bin/bash
set -euo pipefail

echo "--- :packer: Building Windows AMI"
docker run -e AWS_DEFAULT_REGION  -e AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN \
  -v "${HOME}/.aws:/root/.aws" \
  --rm -v "${PWD}:/src" -w /src/packer hashicorp/packer:light \
    build buildkite-ami.json | tee packer.output

image_id=$(grep -Eo "us-east-1: (ami-.+)$" "packer.output" | awk '{print $2}')
echo "AMI for us-east-1 is $image_id"

buildkite-agent meta-data set image_id "$image_id"