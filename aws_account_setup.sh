#!/bin/bash
# Script to create AWS accounts
# First draft
# Author: jayh


function usage()
{
cat <<EOF
create_account.sh [hu]

    Creates a new AWS account in the Connected Home organisation
    This script requires IAM permissions in the CH parent account

    options:
      -h this help
      -p parent account credentials profile name
      -n new account name (in the form product-environment-region)
      -u username of first admin IAM account to create
EOF
}

# read any command line options
while getopts hp:n:u: opt; do
    case ${opt} in
        h) usage; exit 0;;
        p) PROFILE=${OPTARG};;
        n) ACCNAME=${OPTARG};;
        u) IAMUSER=${OPTARG};;
        :) echo "Option -$OPTARG requires an argument." >&2 && exit 1;;
    esac
done

# shift away any command line options that have already been read
shift $((OPTIND-1))

if [[ -z $PROFILE ]]; then
  echo "-p profile required. Exiting."
  exit 1
fi

if [[ -z $ACCNAME ]]; then
  echo "-n new account name required. Exiting."
  exit 1
fi

if [[ -z $IAMUSER ]]; then
  echo "-u username required. Exiting."
  exit 1
fi

#other config
CONCIERGEEMAIL="cmartinl@amazon.co.uk,aws-britishgas-acct-team@amazon.com"
CONCIERGENAME="Claudia"

#create account
echo "About to create new account called ${ACCNAME}"
echo "Create account? y/n"
read CREATE
if [[ $CREATE = "y" ]]; then
  aws --profile ${PROFILE} organizations create-account --email awsbilling+${ACCNAME}@bgch.co.uk --account-name ${ACCNAME} --iam-user-access-to-billing DENY
fi

#get new account number
while [[ -z $ACCNUMBER ]]; do
  ACCNUMBER=$(aws --profile ${PROFILE} organizations list-create-account-status --states SUCCEEDED | jq -r '.CreateAccountStatuses[] |.AccountName,.AccountId' | grep -A1 ${ACCNAME} | tail -n 1)
  echo "Waiting for account creation"
  sleep 5
done
echo "Account ${ACCNAME} with account number ${ACCNUMBER} created"

#get temp creds
echo "Assuming admin role in new account..."
creds_array=($(aws --profile ${PROFILE} sts assume-role --role-arn arn:aws:iam::${ACCNUMBER}:role/OrganizationAccountAccessRole --role-session-name sample | jq -r '.Credentials.SecretAccessKey, .Credentials.AccessKeyId, .Credentials.SessionToken')) && export AWS_SECRET_ACCESS_KEY=${creds_array[0]} && export AWS_ACCESS_KEY_ID=${creds_array[1]} && export AWS_SESSION_TOKEN=${creds_array[2]}

#create initial user
echo "Creating new admin user ${IAMUSER} in ${ACCNAME}"
aws iam create-user --user-name ${IAMUSER}
aws iam attach-user-policy --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --user-name ${IAMUSER}
PWD=`openssl rand -base64 12`
aws iam create-login-profile --user-name ${IAMUSER} --password-reset-required --password ${PWD}
echo "${IAMUSER} / ${PWD}"
echo "Credentials:"
IAMCREDS=$(aws iam create-access-key --user-name ${IAMUSER} | jq -r '.[].AccessKeyId, .[].SecretAccessKey')
echo ${IAMCREDS}

#create initial read only service user
echo "Creating new read only user aws.events.ro in ${ACCNAME}"
aws iam create-user --user-name aws.events.ro
aws iam attach-user-policy --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess --user-name aws.events.ro
echo "Credentials:"
ROCREDS=$(aws iam create-access-key --user-name aws.events.ro | jq -r '.[].AccessKeyId, .[].SecretAccessKey')
echo ${ROCREDS}

#set IAM config
echo "Creating account alias/login url of https://${ACCNAME}.signin.aws.amazon.com/console"
ALIAS=''
ALIASTOTRY=${ACCNAME}
while [[ -z $ALIAS ]]; do 
  aws iam create-account-alias --account-alias ${ALIASTOTRY}
  ALIAS=$(aws iam list-account-aliases | jq -r '.AccountAliases[]')
  if [[ -z $ALIAS ]]; then 
    echo "Account alias not created? Type a new one to try: "
    read ALIASTOTRY
  fi
done
echo "Alias ${ALIAS} created"
echo "Adding password policy"
aws iam update-account-password-policy --minimum-password-length 12 --allow-users-to-change-password

echo "Create AWS conceirge email? This will open a new email in your default client. y/n"
read CREATEEMAIL
if [[ $CREATEEMAIL = "y" ]]; then
  open "mailto:${CONCIERGEEMAIL}?subject=New account setup&body=Hi ${CONCIERGENAME},  I've created a new account, please can you configure it with our usual settings? ${ACCNAME}  ${ACCNUMBER}  Thanks "
fi
echo "${ACCNAME}  ${ACCNUMBER}"
echo "console url: ${ALIAS}"
echo "root username: awsbilling+${ACCNAME}@bgch.co.uk"
echo "${IAMUSER} / ${PWD}"
echo ${IAMCREDS}
echo "aws.events.ro"
echo "${ROCREDS}"

echo "All done. Now you need to:"
echo " * Add the aws.events.ro credentials to the list in puppet-ops heiradata"
echo " * Contact the AWS concierge to complete the setup of the account (using the email created above if you agreed to it)"
echo " * Set a root password using the forgotten password link here: https://console.aws.amazon.com/?nc2=h_m_mc"
echo " * Add that password to OpsBag"
echo " * Enable MFA on the root account and add to the MFA phone"
echo " * Screenshot the MFA QR code, gpg encrypt it and add it to the ops-secrets repo"
echo " * Fill in the Confluence page with the new account details here: "
echo "    https://confluence.bgchtest.info/display/SRE/AWS+Accounts+-+List+and+Creation+Process#AWSAccounts-ListandCreationProcess-newaccountsetup"
