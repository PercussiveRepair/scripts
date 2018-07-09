#!/bin/bash
# Script to create AWS accounts
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
EOF
}

# read any command line options
while getopts hp:n: opt; do
    case ${opt} in
        h) usage; exit 0;;
        p) PROFILE=${OPTARG};;
        n) ACCNAME=${OPTARG};;
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

#run account detection lambda
echo "Running account database lambda"
aws --profile ${PROFILE} lambda invoke --function-name chaimaccountsend chaimaccountsend.log
echo "Lamdba log saved to chaimaccountsend.log"

#get temp creds
echo "Assuming admin role in new account..."
creds_array=($(aws --profile ${PROFILE} sts assume-role --role-arn arn:aws:iam::${ACCNUMBER}:role/OrganizationAccountAccessRole --role-session-name sample | jq -r '.Credentials.SecretAccessKey, .Credentials.AccessKeyId, .Credentials.SessionToken')) && export AWS_SECRET_ACCESS_KEY=${creds_array[0]} && export AWS_ACCESS_KEY_ID=${creds_array[1]} && export AWS_SESSION_TOKEN=${creds_array[2]}

# create initial read only service user
echo "Creating new read only user aws.events.ro in ${ACCNAME}"
aws iam create-user --user-name aws.events.ro
aws iam attach-user-policy --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess --user-name aws.events.ro
ROCREDS=($(aws iam create-access-key --user-name aws.events.ro | jq -r '.[].AccessKeyId, .[].SecretAccessKey')) && RO_ACCESS_KEY=${ROCREDS[0]} && RO_SECRET_KEY=${ROCREDS[1]}
echo "Read Only credentials created"

#set IAM config
echo "Creating account alias/login url"
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
echo "Alias https://${ALIAS}.signin.aws.amazon.com/console created"
echo "Adding password policy"
aws iam update-account-password-policy --minimum-password-length 12 --allow-users-to-change-password --max-password-age 100
echo "Alias added"

#create concierge support case
echo "Creating a new concierge AWS support case in ${PROFILE} to add Enterprise Support, Tax settings and invoicing information to the new account"
CASEID=$(aws --profile ${PROFILE}  --region us-east-1 support create-case --subject "New AWS account created - please configure as per other child accounts"  --service-code customer-account --severity-code low --category-code change-account-details --communication-body "Hi, I have created a new AWS account: ${ACCNAME}  ${ACCNUMBER}. Please can you configure Enterprise Support, invoicing information and VAT number as in our payer account, Thanks, Hive SRE" --cc-email-addresses "sre@bgch.co.uk" "aws-hive-account-team@amazon.co.uk" | jq -r '.caseId')
echo "New support case id: ${CASEID} created in ${PROFILE} account for final account configuration. sre@bgch.co.uk copied"

#Output results
echo ""
echo "Account Creation Complete"
echo "${ACCNAME}  ${ACCNUMBER}"
echo "console url: https://${ALIAS}.signin.aws.amazon.com/console"
echo "root username: awsbilling+${ACCNAME}@bgch.co.uk"
echo "support email: ${ACCNAME}.awsnotifications@hivehome.com"
echo "support case id: ${CASEID}"
echo "aws.events.ro creds to paste into puppet-ops hieradata/creds-common.yaml"
echo "  ${ACCNAME}:"
echo "    '${RO_ACCESS_KEY}': 'DEC::GPG[${RO_SECRET_KEY}]!'"
echo " "

# running post account creation scripts
echo "Continue with other account configuration steps? This includes CHAIM and security monkey role setup and CloudTrail and GuardDuty enablement in the new account. Requires a set of valid, local secadmin-prod credentials. y/n"
read POSTACCOUNT
if [[ ${POSTACCOUNT} = "y" ]]; then
  # check for secadmin-prod creds
  CREDSFILE=$(echo $HOME/.aws/credentials)

  if [[ -f ${CREDSFILE} ]]; then
    if [[ -z $(cat ${CREDSFILE} | grep secadmin-prod) ]]; then
      echo "secadmin-prod creds not found"
    fi
  fi
  ./chaim_roles_setup.sh
  sleep 2
  ./secmonkey_role_setup.sh
  sleep 2
  ./cloudtrail_setup.sh -i ${ACCNUMBER}
  sleep 2
  ./guardduty_setup.sh -i ${ACCNUMBER} -n ${ACCNAME}

  echo "Enabling all AWS Organizations Service Control Policies. Continue? y/n"
  read ENABLESCP
  if [[ ${ENABLESCP} = "y" ]]; then
    for POLICY in $(aws --profile ${PROFILE} organizations list-policies --filter SERVICE_CONTROL_POLICY | jq -r '.Policies[] | .id' | grep -v p-FullAWSAccess); do
      aws --profile ${PROFILE} organizations attach-policy --policy-id ${POLICY} --target-id ${ACCNUMBER}
    done
  fi
fi

#Output results again
echo ""
echo "Account Creation Complete"
echo "${ACCNAME}  ${ACCNUMBER}"
echo "console url: https://${ALIAS}.signin.aws.amazon.com/console"
echo "root username: awsbilling+${ACCNAME}@bgch.co.uk"
echo "support email: ${ACCNAME}.awsnotifications@hivehome.com"
echo "support case id: ${CASEID}"
echo "aws.events.ro creds to paste into puppet-ops hieradata/creds-common.yaml"
echo "  ${ACCNAME}:"
echo "    '${RO_ACCESS_KEY}': 'DEC::GPG[${RO_SECRET_KEY}]!'"
echo " "

echo "All done. Now you need to:"
echo " * Verify the AWS support ticket has been created (in the master billing account support console) to complete the setup of the account"
echo " * Set a root password using the forgotten password link here: https://console.aws.amazon.com/?nc2=h_m_mc"
echo " * Add that password to OpsBag under aws/${ACCNAME}"
echo " * Enable MFA on the root account and add to ops-otp-cli https://github.com/ConnectedHomes/ops-otp-cli#to-add-a-new-service"
echo " * Screenshot the MFA QR code, gpg encrypt it and add it to https://github.com/ConnectedHomes/ops-secrets repo"
echo " * Get a new gmail group created called ${ACCNAME}.awsnotifications@hivehome.com and add the product teams email to it as member"
echo " * Set that new ${ACCNAME}.awsnotifications@hivehome.com email as the Operations and Security Alternative Contacts in the new account: https://console.aws.amazon.com/billing/home?#/account" 
echo " * Add the aws.events.ro credentials to the list in puppet-ops hieradata"
echo " * Fill in the Confluence page with the new account details here: "
echo "    https://confluence.bgchtest.info/display/SRE/AWS+Accounts+-+List+and+Creation+Process#AWSAccounts-ListandCreationProcess-newaccountsetup"


