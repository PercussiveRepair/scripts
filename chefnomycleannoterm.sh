#!/bin/bash

# Removes a host from EC2, nomy & chef

if [[ -z "$1" ]]; then
  echo "$0 <hostname required>"
  exit 1
fi

HOST=$1
QUAD=$(echo $HOST | cut -f2 -d.)
INSTANCEID=$(aws --profile $QUAD ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId]' --output text --filter "Name=tag:FQDN,Values=$HOST*")

echo "removing from nomy"
ruby -e "require 'okta/nomy/client'
  Okta::Nomy::Client::ApiClient.new().instances.delete('$HOST')"
echo "removing chef client & node info"
yes | knife client delete $HOST
yes | knife node delete $HOST
