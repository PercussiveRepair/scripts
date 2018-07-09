#!/bin/bash
################################################################################
# Authors Joe Jarman, Mark Davison
# Last updated: 2018-04-04
# Script to create GuardDuty invites for a list of accounts
#
# Files MUST be in your PWD
# File accounts.txt should be in the format of one account number followed by
# a space then the account name.
# i.e. 012345678901 example-account
#
# File regions.txt is similarly a formatted list of all the regions.
#
# GuardDuty setup is stateful so it is safe to rerun this script against
# accounts which are already setup.
#
# Note secadmin-prod, 499223386158 is hardcoded as the master account
#
# Bug/Future Improvement:
#  Email address used must match the one in the Organisations list we've patterned
#  this but really we should perform a lookup in the Organisations account.
#
# Requires: bash
# Recommended: chaim
################################################################################
chaim=$(which chaim)
if [[ -z "${chaim}" ]];then
  chaim="${HOME}/src/aimcli/dist/chaim/chaim"
fi

if [[ -f "${chaim}" ]];then
  "${chaim}" secadmin-prod -r apu -d 1
 else
  echo "Unable to find chaim in the expected location, proceeding on the assumption that the standard credentials file has the necessary"
fi
while IFS=' ' read -r number name
do
  # Region loop runs in parallel
  for region in $(cat regions.txt);do
    DETECTOR=$(aws --profile secadmin-prod --region "${region}" guardduty list-detectors | jq -r '.DetectorIds[]')
      if [[ "${DETECTOR}" == '' ]];then
        aws --profile secadmin-prod --region "${region}" guardduty create-detector --enable
        DETECTOR=$(aws --profile secadmin-prod --region "${region}" guardduty list-detectors | jq -r '.DetectorIds[]')
        if [[ "${DETECTOR}" == '' ]];then
          echo "unable to find or create Detector ID"
          exit 1
        fi
      fi
        aws --profile secadmin-prod --region "${region}" guardduty create-members --detector-id "${DETECTOR}" --account-details AccountId="${number}",Email="awsbilling+${name}@bgch.co.uk"
  if [[ ${?} != 0 ]];then
    echo "unable to create members for $name in $region, continuing..."
    continue
  fi
    aws --profile secadmin-prod --region "${region}" guardduty invite-members --account-ids "${number}" --detector-id "${DETECTOR}"
  if [[ ${?} != 0 ]];then
    echo "unable to create invitation for $name in $region"
    continue
  fi
  "${chaim}" "${name}" -r apu -d 600
   INVITATIONID=$(aws --profile "${name}" --region "${region}" guardduty list-invitations | jq -r '.Invitations[].InvitationId')
  if [[ "${INVITATIONID}" == '' ]];then
    echo "unable to find invitation ID"
    continue
  fi
  echo "Invitation ID: ${INVITATIONID}"
    aws --profile "${name}" --region "${region}" guardduty create-detector
    DETECTOR=$(aws --profile "${name}" --region "${region}" guardduty list-detectors | jq -r '.DetectorIds[]')
  if [[ "${DETECTOR}" == '' ]];then
    echo "unable to find detector ID"
    continue
  fi
  echo "Detector ID: ${INVITATIONID}"
    aws --profile "${name}" --region "${region}" guardduty accept-invitation --detector-id "${DETECTOR}" --invitation-id "${INVITATIONID}" --master-id 499223386158
  done
done < accounts.txt

