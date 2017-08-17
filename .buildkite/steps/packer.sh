#!/bin/bash
set -euo pipefail

docker run -e AWS_DEFAULT_REGION  -e AWS_ACCESS_KEY_ID \
	-e AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN \
	-v "${HOME}/.aws:/root/.aws" \
	--rm -v "${PWD}:/src" -w /src/packer hashicorp/packer:light \
		build buildkite-ami.json | tee packer.output