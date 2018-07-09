#!/bin/bash
# Script to create Security Monkey role in new accounts
# Author: jayh

# create secmonkey iam roles
echo "Creating secmonkey IAM role"
aws --region eu-west-1 cloudformation create-stack --stack-name secmonkey-role --template-body file://cloudformation/secmonkey-role-cf.yaml --capabilities CAPABILITY_NAMED_IAM
aws --region eu-west-1 cloudformation wait stack-create-complete --stack-name secmonkey-role
aws cloudformation update-termination-protection --stack-name secmonkey-role --enable-termination-protection
echo "Create secmonkey IAM roles complete"