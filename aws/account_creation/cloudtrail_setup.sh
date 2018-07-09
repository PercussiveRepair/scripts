#!/bin/bash
# Script to create Cloudtrail config in new accounts
# Author: jayh

function usage()
{
cat <<EOF
cloudtrail_setup.sh [hi]

    Enables cloudtrail in newly created AWS accounts
    Uses ENV credentials as created in aws_account_setup.sh

    options:
      -h this help
      -i new account id
EOF
}

# read any command line options
while getopts h:i: opt; do
    case ${opt} in
        h) usage; exit 0;;
        i) ACCID=${OPTARG};;
        :) echo "Option -$OPTARG requires an argument." >&2 && exit 1;;
    esac
done

# shift away any command line options that have already been read
shift $((OPTIND-1))

if [[ -z $ACCID ]]; then
  echo "-i accountid required. Exiting."
  exit 1
fi

# config
STACKSETNAME="CloudtrailCH"
SECURITYAWSACCOUNTNAME="secadmin-prod"
REGION="eu-west-1"  
STACKSETMASTERID='499223386158'
ALSQSSTACK="secadmin--prod--ALSQS--0"

# add Stack sets admin permissions
echo "Creating new Cloudtrail Stackset permissions for new account ${ACCID}"
aws --region ${REGION} cloudformation create-stack --stack-name stacksetsadmin --template-body file://cloudformation/managed_account_role.template --parameters ParameterKey=MasterAccountId,ParameterValue=${STACKSETMASTERID} --capabilities CAPABILITY_NAMED_IAM
aws --region ${REGION} cloudformation wait stack-create-complete --stack-name stacksetsadmin
aws cloudformation update-termination-protection --stack-name stacksetsadmin --enable-termination-protection

# create cloudtrail stack set for account

echo "Adding new account ${ACCID} to the Cloudtrail Stackset"
aws --region ${REGION} --profile ${SECURITYAWSACCOUNTNAME} cloudformation create-stack-instances --stack-set-name ${STACKSETNAME} --accounts ${ACCID} --regions ${REGION}


# # add newly generated sns topic to the SQS queue for alertlogic 

# # first get the stack id of the newly created cloudtrail stack
# CLOUDTRAILSTACKID=$(aws --region ${REGION} --profile ${SECURITYAWSACCOUNTNAME} cloudformation list-stack-instances --stack-set-name CloudtrailCH | jq '.Summaries[] | select(.Account=="${ACCID}")|.StackId' | cut -d / -f 2 2>&1)
# echo "CloudtrailStackID = ${CLOUDTRAILSTACKID}"

# # now return the arn for the sns topic created in the cloudtrailstack
# SNSARN=$(aws --region ${REGION} cloudformation list-stack-resources --stack-name ${CLOUDTRAILSTACKID} | jq -r '.[][]|select(.ResourceType=="AWS::SNS::Topic")|.PhysicalResourceId' 2>&1)
# echo "SNSARN = ${SNSARN}"

# # pull down the current cloudformation template for the alertlogic SQS stack for manipulation
# SQSJSON=$(aws --region ${REGION} --profile ${SECURITYAWSACCOUNTNAME} cloudformation get-template --stack-name ${ALSQSSTACK}| jq '.TemplateBody.Resources.ALSQSQueuePolicy.Properties.PolicyDocument.Statement.Condition.ArnLike."aws:SourceArn" += ["arn:aws:sns:'${REGION}':'${ACCID}':*"] |.TemplateBody' 2>&1)

# # upload the amended json to the cloudformation stack
# echo "Updating the Alertlogic SQS Queue for ingestion of new account ${ACCID} cloudtrail logs"
# aws --region ${REGION} --profile ${SECURITYAWSACCOUNTNAME} cloudformation update-stack --stack-name ${ALSQSSTACK} --template-body "$(echo ${SQSJSON})" --capabilities CAPABILITY_NAMED_IAM
# aws --region ${REGION} cloudformation wait stack-create-complete --stack-name ${ALSQSSTACK}

# SQSHTTPS=$(aws --region ${REGION} --profile ${SECURITYAWSACCOUNTNAME}  cloudformation list-stack-resources --stack-name ${ALSQSSTACK} | jq --raw-output '.[][]|select(.ResourceType=="AWS::SQS::Queue")|.PhysicalResourceId' 2>&1)
# echo "SQSHTTPS = ${SQSHTTPS}"

# SQSARN=$(aws --region ${REGION} --profile ${SECURITYAWSACCOUNTNAME} sqs get-queue-attributes --queue-url ${SQSHTTPS} --attribute-names "QueueArn" | jq -r '.[][]' 2>&1)
# echo "SQSARN = ${SQSARN}"

# # subscribe the sqs queue to the sns topic
# echo "Subscribing the sqs queue to the sns topic - Cloudtrail logs for new account ${ACCID} will be ingested following this (if all steps above completed successfully)"

# aws --region ${REGION} --profile ${SECURITYAWSACCOUNTNAME} sns subscribe --topic-arn ${SNSARN} --notification-endpoint ${SQSARN} --protocol sqs