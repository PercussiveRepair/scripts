#!/usr/bin/env python

# Copyright 2014 Rocket-Internet
# Luca Bruno <luca.bruno@rocket-internet.de>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""
SecurityMonkey AWS role provisioning script
Grab credentials from ~/.boto (or other standard credentials sources).
Optionally accept "profile_name" as CLI parameter.
"""

import re
import sys, json
import urllib
import boto3
from botocore.exceptions import ClientError

# FILL THIS IN
# Supervision accounts that can assume monitoring role
secmonkey_arns = [
    'arn:aws:iam::738122424235:role/SecurityMonkeyInstanceProfile',
    'arn:aws:iam::499223386158:role/SecurityMonkeyInstanceProfile'
]

def secmonkey_policy_statement(secmonkey_arn = None):
  return {
    "Action": "sts:AssumeRole",
    "Principal": {
      "AWS": secmonkey_arn
    },
    "Effect": "Allow",
    "Sid": ""
  }

trust_relationships = {
    "Version": "2008-10-17",
    "Statement": []
}

for arn in secmonkey_arns:
    statement = secmonkey_policy_statement(arn)
    trust_relationships['Statement'].append(statement)

# Role with restricted security policy (list/get only)
role_name = 'SecurityMonkey'
role_policy_name = 'SecurityMonkeyPolicy'

# Fix manually created roles:
# - remove manually created managed policies
# - remove manually created inline policies with different naming scheme (e.g. SecurityMonkeyReadOnly)
fix_roles_allowed = True

policy = \
         '''
{
  "Statement": [
    {
      "Action": [
          "acm:describecertificate",
           "acm:listcertificates",
           "cloudtrail:describetrails",
           "cloudtrail:gettrailstatus",
           "config:describeconfigrules",
           "config:describeconfigurationrecorders",
           "directconnect:describeconnections",
           "ec2:describeaccountattributes",
           "ec2:describeaddresses",
           "ec2:describedhcpoptions",
           "ec2:describeflowlogs",
           "ec2:describeimages",
           "ec2:describeinstances",
           "ec2:describeinternetgateways",
           "ec2:describekeypairs",
           "ec2:describenatgateways",
           "ec2:describenetworkacls",
           "ec2:describenetworkinterfaces",
           "ec2:describeregions",
           "ec2:describeroutetables",
           "ec2:describesecuritygroups",
           "ec2:describesnapshots",
           "ec2:describesubnets",
           "ec2:describetags",
           "ec2:describevolumes",
           "ec2:describevpcendpoints",
           "ec2:describevpcpeeringconnections",
           "ec2:describevpcs",
           "ec2:describevpngateways",
           "ec2:describevpnconnections",
           "elasticloadbalancing:describeloadbalancerattributes",
           "elasticloadbalancing:describeloadbalancerpolicies",
           "elasticloadbalancing:describeloadbalancers",
           "elasticloadbalancing:describelisteners",
           "elasticloadbalancing:describerules",
           "elasticloadbalancing:describesslpolicies",
           "elasticloadbalancing:describetags",
           "elasticloadbalancing:describetargetgroups",
           "elasticloadbalancing:describetargetgroupattributes",
           "elasticloadbalancing:describetargethealth",
           "es:describeelasticsearchdomainconfig",
           "es:listdomainnames",
           "glacier:DescribeVault",
           "glacier:GetVaultAccessPolicy",
           "glacier:ListTagsForVault",
           "glacier:ListVaults",
           "iam:getaccesskeylastused",
           "iam:getgroup",
           "iam:getgrouppolicy",
           "iam:getloginprofile",
           "iam:getpolicyversion",
           "iam:getrole",
           "iam:getrolepolicy",
           "iam:getservercertificate",
           "iam:getuser",
           "iam:getuserpolicy",
           "iam:listaccesskeys",
           "iam:listattachedgrouppolicies",
           "iam:listattachedrolepolicies",
           "iam:listattacheduserpolicies",
           "iam:listentitiesforpolicy",
           "iam:listgrouppolicies",
           "iam:listgroups",
           "iam:listinstanceprofilesforrole",
           "iam:listmfadevices",
           "iam:listpolicies",
           "iam:listrolepolicies",
           "iam:listroles",
           "iam:listsamlproviders",
           "iam:listservercertificates",
           "iam:listsigningcertificates",
           "iam:listuserpolicies",
           "iam:listusers",
           "kms:describekey",
           "kms:getkeypolicy",
           "kms:getkeyrotationstatus",
           "kms:listaliases",
           "kms:listgrants",
           "kms:listkeypolicies",
           "kms:listkeys",
           "lambda:listfunctions",
           "rds:describedbclusters",
           "rds:describedbclustersnapshots",
           "rds:describedbinstances",
           "rds:describedbsecuritygroups",
           "rds:describedbsnapshots",
           "rds:describedbsubnetgroups",
           "redshift:describeclusters",
           "route53:listhostedzones",
           "route53:listresourcerecordsets",
           "route53domains:listdomains",
           "route53domains:getdomaindetail",
           "s3:getbucketacl",
           "s3:getbucketcors",
           "s3:getbucketlocation",
           "s3:getbucketlogging",
           "s3:getbucketnotification",
           "s3:getbucketpolicy",
           "s3:getbuckettagging",
           "s3:getbucketversioning",
           "s3:getbucketwebsite",
           "s3:getinventoryconfiguration",
           "s3:getlifecycleconfiguration",
           "s3:getmetricsconfiguration",
           "s3:getreplicationconfiguration",
           "s3:getanalyticsconfiguration",
           "s3:getaccelerateconfiguration",
           "s3:listallmybuckets",
           "ses:getidentityverificationattributes",
           "ses:listidentities",
           "ses:listverifiedemailaddresses",
           "ses:sendemail",
           "sns:gettopicattributes",
           "sns:listsubscriptionsbytopic",
           "sns:listtopics",
           "sqs:getqueueattributes",
           "sqs:listqueues"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
'''

def secmonkey_arns_in_policy(secmonkey_arns = None, current_policy = None):
  role_configured = True

  principals = []
  missing_arns = []

  for p in current_policy['Statement']:
    if p['Action'] == 'sts:AssumeRole':
      if 'AWS' in p['Principal']:
        principals.append(p['Principal']['AWS'])

  for secmonkey_arn in secmonkey_arns:
    if not secmonkey_arn in principals:
      role_configured = False
      missing_arns.append(secmonkey_arn)

  return role_configured, missing_arns

def main(profile = None, role_recreate_allowed = False):

  # Sanitize JSON
  assume_policy = json.dumps(trust_relationships)
  security_policy = json.dumps(json.loads(policy))

  # Connect to IAM
  (role_exist, role_configured, recreate_profile, current_policy) = (False, False, False, '')

  try:
      session = boto3.Session(profile_name = profile)
      iam = session.client('iam')
      iam.list_roles()
  except ClientError as e:
      sys.exit('Authentication failed, please check your credentials under ~/.boto')

  # Check if role already exists
  paginator = iam.get_paginator('list_roles')

  for rlist in paginator.paginate():
    for r in rlist['Roles']:
      if r['RoleName'] == role_name:
        role_exist = True
        current_policy = r['AssumeRolePolicyDocument']
        role_configured, missing_arns = secmonkey_arns_in_policy(secmonkey_arns, current_policy)
        if not role_configured:
          for secmonkey_arn in missing_arns:
            statement = secmonkey_policy_statement(secmonkey_arn)
            current_policy['Statement'].append(statement)

          assume_policy = json.dumps(current_policy)

  # If role configured check if security policy needs to be updated
  if role_configured:

      if fix_roles_allowed:
          fix_roles(iam)

      try:
          role_policy = iam.get_role_policy(RoleName=role_name, PolicyName=role_policy_name)
      except ClientError as e:
          if e.response['Error']['Code'] == 'NoSuchEntity':
              # Add our own role policy
              iam.put_role_policy(RoleName=role_name, PolicyName=role_policy_name, PolicyDocument=security_policy)
              print('Added role "%s", linked to ARNs "%s".' % (role_name, ",".join(secmonkey_arns)))
              sys.exit()
          else:
              sys.exit('Checking role policy {} failed, unknown error: {}'.format(role_policy_name, err.message))

      current_security_policy = role_policy['PolicyDocument']
      desired_security_policy = json.loads(policy)

      if cmp(current_security_policy, desired_security_policy) == 0:
          sys.exit('Role "%s" already configured, not touching it.' % role_name)
      else:
          iam.put_role_policy(RoleName=role_name, PolicyName=role_policy_name, PolicyDocument=security_policy)
          print('Updated role "%s", linked to ARNs "%s".' % (role_name, ",".join(secmonkey_arns)))
          sys.exit()

  # Add SecurityMonkey monitoring role and link it to supervisor ARN
  if not role_exist:
      print('Created role {}'.format(role_name))
      role = iam.create_role(RoleName=role_name, AssumeRolePolicyDocument=assume_policy)
  else:
      print('Updated assume role policy for {} role'.format(role_name))
      role = iam.update_assume_role_policy(RoleName=role_name, PolicyDocument=assume_policy)

  # Add our own role policy
  iam.put_role_policy(RoleName=role_name, PolicyName=role_policy_name, PolicyDocument=security_policy)
  print('Updated role "%s", linked to ARNs "%s".' % (role_name, ",".join(secmonkey_arns)))


def fix_roles(iam):

    # Detach managed policies
    attached_policies = iam.list_attached_role_policies(RoleName=role_name)
    for policy in attached_policies['AttachedPolicies']:
        iam.detach_role_policy(RoleName=role_name, PolicyArn=policy['PolicyArn'])
        print('Detached managed policy {} from role {}'.format(policy['PolicyName'], role_name))

    inline_policies = iam.list_role_policies(RoleName=role_name)
    for policy_name in inline_policies['PolicyNames']:
        if policy_name != role_policy_name:
            iam.delete_role_policy(RoleName=role_name, PolicyName=policy_name)
            print('Deleted inline policy {} from role {}'.format(policy_name, role_name))


if __name__ == "__main__":
    profile = None

    if len(sys.argv) >= 2:
        profile = sys.argv[1]
        main(profile)