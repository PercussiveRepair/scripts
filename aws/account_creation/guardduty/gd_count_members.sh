################################################################################
# Authors Mark Davison
# Last updated: 2018-02-20
# script to count number of GuardDuty members in the master account
#
# Files MUST be in your PWD
# File regions.txt should be formatted of one region per line. It should only
# contain regions which GuardDuty is available in, this file will need extending
# as more regions are supported.
#
# Note secadmin-prod, 499223386158 is hardcoded as the master account
#
# Requires: bash
################################################################################

printf "Region,#Accounts\n"
for region in $(aws --profile secadmin-prod ec2 describe-regions --output text | cut -f 3); do
  DETECTOR=$(aws --profile secadmin-prod --region "${region}" guardduty list-detectors | jq -r '.DetectorIds[]')
  if [[ ${DETECTOR} == '' ]];then
    echo "unable to find detector ID"
    continue
  fi
  counter=$(aws --profile secadmin-prod --region "${region}" guardduty list-members --detector-id "${DETECTOR}" | grep '"RelationshipStatus": "Enabled"' | wc -l)
printf "$region,$counter\n"
done
printf "\nNote: the master account (secadmin-prod,499223386158) does not appear
as a member so this result should be one less than the total number of accounts\n"
