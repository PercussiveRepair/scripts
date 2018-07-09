#!/bin/bash
# Script to create CHAIM roles in new accounts
# Author: jayh

# create chaim iam roles
echo "Creating CHAIM IAM roles"
aws --region eu-west-1 cloudformation create-stack --stack-name chaim-roles --template-body file://cloudformation/chaim-roles-cf.yaml --parameters ParameterKey=LambdaARN,ParameterValue=arn:aws:lambda:eu-west-1:499223386158:function:slack-iam-sso ParameterKey=AccountARN,ParameterValue=arn:aws:iam::499223386158:root --capabilities CAPABILITY_NAMED_IAM
aws --region eu-west-1 cloudformation wait stack-create-complete --stack-name chaim-roles
aws cloudformation update-termination-protection --stack-name chaim-roles --enable-termination-protection
echo "Create CHAIM IAM roles complete"