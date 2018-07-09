#!/bin/bash
################################################################################
# Authors Joe Jarman, Mark Davison
# Last updated: 2018-04-04
# Script to create GuardDuty invites for a list of accounts
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
################################################################################

function usage()
{
cat <<EOF
guardduty_setup.sh [hni]

    Enables guardduty in newly created AWS accounts
    Uses ENV credentials as created in aws_account_setup.sh

    options:
      -h this help
      -n new account name
      -i new account id
EOF
}

# read any command line options
while getopts hi:n: opt; do
    case ${opt} in
        h) usage; exit 0;;
        i) ACCID=${OPTARG};;
        n) ACCNAME=${OPTARG};;
        :) echo "Option -$OPTARG requires an argument." >&2 && exit 1;;
    esac
done

# shift away any command line options that have already been read
shift $((OPTIND-1))

if [[ -z "${ACCID}" ]]; then
  echo "-i accountid required. Exiting."
  exit 1
fi

if [[ -z "${ACCNAME}" ]]; then
  echo "-n new account name required. Exiting."
  exit 1
fi

# check for secadmin-prod creds
CREDSFILE=$(echo "${HOME}/.aws/credentials")

if [[ -f "${CREDSFILE}" && -z $(cat "${CREDSFILE}" | grep secadmin-prod) ]]; then
  echo "secadmin-prod credentials not found"
fi

for region in $(aws --profile secadmin-prod ec2 describe-regions --output text | cut -f 3 | sort -u); do

  echo "Adding account ${ACCNAME} ${ACCID} to Guardduty in secadmin-prod for region ${region}"
  # secadmin-prod account
  # find or create detector in admin account
  ADMINDETECTOR=$(aws --profile secadmin-prod --region "${region}" guardduty list-detectors | jq -r '.DetectorIds[]')
  if [[ -z ${ADMINDETECTOR} ]]; then
    aws --profile secadmin-prod --region "${region}" guardduty create-detector --enable
    sleep 1
    ADMINDETECTOR=$(aws --profile secadmin-prod --region "${region}" guardduty list-detectors | jq -r '.DetectorIds[]')
  fi

  if [[ -z ${ADMINDETECTOR} ]]; then
    echo "Unable to find or create Detector ID"
    exit 1
  else
    echo "GuardDuty admin account detector id: ${ADMINDETECTOR}"
  fi

  # add new account to detector as a member
  MEMBERCREATE=$(aws --profile secadmin-prod --region "${region}" guardduty create-members --detector-id "${ADMINDETECTOR}" --account-details AccountId="${ACCID}",Email="awsbilling+${ACCNAME}@bgch.co.uk" | jq -r '.UnprocessedAccounts[].Result')
  if [[ -z ${MEMBERCREATE} ]]; then
    echo "Member created"
  else
    echo "Unable to create members for ${ACCNAME} in ${region}. Continuing... Error: ${MEMBERCREATE}"
    continue
  fi

  # send invitation
  SENDINVITE=$(aws --profile secadmin-prod --region "${region}" guardduty invite-members --account-ids "${ACCID}" --detector-id "${ADMINDETECTOR}" --disable-email-notification | jq -r '.UnprocessedAccounts[].Result')
  if [[ -z ${SENDINVITE} ]]; then
    echo "Invite sent"
  else
    echo "Unable to create invitation for ${ACCNAME} in ${region}. Continuing... Error: ${SENDINVITE} "
    continue
  fi

  # The remainder of the script runs against the new account
  echo "Processing invitation in new account ${ACCNAME} ${ACCID}"
  # find invitation id
  count=0
  INVITATIONID=""
  while [[ -z ${INVITATIONID} && count -lt 5 ]]; do
    sleep 1
    INVITATIONID=$(aws --region "${region}" guardduty list-invitations | jq -r '.Invitations[].InvitationId')
    (( count++ ))
  done
  if [[ -z ${INVITATIONID} ]]; then
    echo "Unable to find invitation ID"
    continue
  else
    echo "Invitation ID: ${INVITATIONID}"
  fi

  # find or create detector in new account
  DETECTOR=$(aws --region "${region}" guardduty list-detectors | jq -r '.DetectorIds[]')
  if [[ -z ${DETECTOR} ]]; then
    aws --region "${region}" guardduty create-detector
    sleep 1
    DETECTOR=$(aws --region "${region}" guardduty list-detectors | jq -r '.DetectorIds[]')
  fi
  if [[ -z ${DETECTOR} ]]; then
    echo "Unable to find detector ID"
    continue
  fi
  echo "Detector ID: ${DETECTOR}"

  # accept the invitation
  ACCEPTINVITE=$(aws --region "${region}" guardduty accept-invitation --detector-id "${DETECTOR}" --invitation-id "${INVITATIONID}" --master-id 499223386158 | jq -r '.UnprocessedAccounts[].Result')
  if [[ -z ${ACCEPTINVITE} ]]; then
    echo "Invite accepted"
  else
    echo "Unable to accept invitation for ${ACCNAME} in ${region}. Continuing... Error: ${ACCEPTINVITE} "
    continue
  fi
  echo ""
done 