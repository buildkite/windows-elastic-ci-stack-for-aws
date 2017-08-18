#!/bin/bash
# shellcheck disable=SC2016
set -uxo pipefail

if [[ $OSTYPE =~ ^darwin ]] ; then
  cutoff_date=$(gdate --date='-1 days' +%Y-%m-%d)
else
  cutoff_date=$(date --date='-1 days' +%Y-%m-%d)
fi

echo "--- Cleaning up resources older than ${cutoff_date}"

# if [[ -n "${AWS_STACK_NAME:-}" ]] ; then
#   echo "--- Deleting stack $AWS_STACK_NAME"
#   aws cloudformation delete-stack --stack-name "$AWS_STACK_NAME"
# fi

echo "--- Deleting old cloudformation stacks"
aws cloudformation describe-stacks \
  --output text \
  --query "$(printf 'Stacks[?CreationTime<`%s`].StackName' "$cutoff_date" )" \
  | xargs -n1 \
  | grep -E "${AWS_STACK_PREFIX}-\d+" \
  | xargs -n1 -t -I% aws cloudformation delete-stack --stack-name "%"

echo "--- Deleting old packer builders"
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=Packer Builder" \
  --query "$(printf 'Reservations[].Instances[?LaunchTime<`%s`].InstanceId' "$cutoff_date")" \
  --output text \
  | xargs -n1 -t -I% aws ec2 terminate-instances --instance-ids "%"
