#!/bin/bash

ACCID=$1

for region in $(aws --profile secadmin-prod ec2 describe-regions --output text | cut -f 3); do

  echo "${region}"
  DETECTOR=$(aws --profile secadmin-prod --region "${region}" guardduty list-detectors | jq -r '.DetectorIds[]')
  aws --profile secadmin-prod --region "${region}" guardduty disassociate-members --account-ids "${ACCID}" --detector-id "${DETECTOR}"
  aws --profile secadmin-prod --region "${region}" guardduty delete-members --account-ids "${ACCID}" --detector-id "${DETECTOR}"
done
