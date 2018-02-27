#! /usr/local/bin/python2

# enumerates boxes in aws accounts by envronment and role

import boto3
import argparse
import json
import sys

environment = ''
role = ''
profile_location = '/Users/jayharrison/.aws/credentials'

if len(sys.argv) == 4:
  account = str(sys.argv[1])
  environment = str(sys.argv[2])
  role = str(sys.argv[3])
elif len(sys.argv) == 3:
  account = str(sys.argv[1])
  if str(sys.argv[2]) in ['dev', 'qa', 'staging', 'perf', 'prod', 'beta']:
    environment = str(sys.argv[2])
  else:
    role = str(sys.argv[2])
elif len(sys.argv) == 2:
  account = str(sys.argv[1])
else:
  print "Usage 'boxes (account) (environment) (role)'"
  sys.exit(0)

#make sure profile is valid
profiles = open(profile_location)
if account in profiles.read():
  profile = account
else:
  print "Unrecognised profile"
  sys.exit(0)

boto3.setup_default_session(profile_name=profile)
client = boto3.client('ec2')

filter_list = []
if role:
  filter_list.append({ 'Name': 'tag:role', 'Values': [role]}) 

if environment:
  filter_list.append({ 'Name': 'tag:environment', 'Values': [environment]})

groups = client.describe_instances(
  Filters=filter_list
)

iplist = []

for instance in groups['Reservations']: 
  for i in instance['Instances']:
    if i['State']['Name'] == 'running':
      env_tag = 'undefined'
      role_tag = 'undefined'
      if 'Tags' in i:
        for t in i['Tags']:
          if 'env' in t['Key'].lower():
            env_tag = t['Value']
          if 'role' in t['Key'].lower():
            role_tag = t['Value']
      iplist.append([env_tag, role_tag, i['InstanceId'], i['PrivateIpAddress'], i['PublicDnsName']] )

iplist.sort()

for row in iplist:
        print("{: <13} {: <20} {: <21} {: <16} {: <20}".format(*row))
