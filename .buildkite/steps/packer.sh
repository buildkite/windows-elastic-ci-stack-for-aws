#!/bin/bash
set -euo pipefail

stack_bucket_path="${BUILDKITE_AWS_STACK_BUCKET}/packer"
packer_file="${packer_hash}.packer"

packer_hash=$(find packer/ -type f -print0 \
  | xargs -0 sha1sum \
  | awk '{print $1}' \
  | sort \
  | sha1sum \
  | awk '{print $1}'
)

echo "Packer files hash is $packer_hash"

if ! aws s3 cp "s3://${stack_bucket_path}/${packer_file}" . ; then
  echo "--- :packer: Building Windows AMI"
  docker run -e AWS_DEFAULT_REGION  -e AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN \
    -v "${HOME}/.aws:/root/.aws" \
    --rm -v "${PWD}:/src" -w /src/packer hashicorp/packer:light \
      build buildkite-ami.json | tee "${packer_file}"
  aws s3 cp "${packer_file}" "s3://${stack_bucket_path}/${packer_file}"
else
  echo "--- :packer: Skipping packer build, no changes"
fi

image_id=$(grep -Eo "us-east-1: (ami-.+)$" "${packer_file}" | awk '{print $2}')
echo "AMI for us-east-1 is $image_id"

buildkite-agent meta-data set image_id "$image_id"