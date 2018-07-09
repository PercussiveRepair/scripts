#!/bin/bash
for region in $(aws --profile secadmin-prod ec2 describe-regions --output text | cut -f 3); do
    DETECTOR=$(aws --profile secadmin-prod --region "${region}" guardduty list-detectors | jq -r '.DetectorIds[]')
    if [[ ${DETECTOR} == '' ]];then echo "unable to find detector ID";continue;fi
    printf "Region: ${region}\n"
    aws --profile secadmin-prod --region "${region}" guardduty list-members --detector-id "${DETECTOR}" --query 'Members[?RelationshipStatus==`Disabled`]'
done
