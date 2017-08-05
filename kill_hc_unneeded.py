#! /usr/bin/python

# allows down/up scaling of test honeycomb environments for connected boiler team

import boto3
import argparse
import pprint
import re

parser = argparse.ArgumentParser(description='Given an ASG, set the instances to 0')
parser.add_argument('-e', '--env',
                    required=True,
                    help='CB HC env')
parser.add_argument('-p', '--profile',
                    required=True,
                    help='AWS profile')
parser.add_argument('-s', '--size',
                    required=True,
                    help='AWS group size: None or Default')
args = parser.parse_args()
env = args.env
while args.size not in ['None', 'Default']:
  parser.error("Size must be None or Default")
else:
  size = args.size

pp = pprint.PrettyPrinter(indent=2)
regex = r"cb-"+ re.escape(env) + r"-hone.*-.*(API|Event|Synthetic|Cassandra|Kairos|Ecosystem|Kafka|Services).*"
pattern = re.compile(regex)

boto3.setup_default_session(profile_name=args.profile)
client = boto3.client('autoscaling')
groups = client.describe_auto_scaling_groups(
           MaxRecords=100
         )
defaults = {'API': 2, 'Event': 1, 'Synthetic': 1, 'cassandra': 2, 'Kairos': 1, 'Ecosystem': 2, 'Kafka': 2, 'Services': 1}

for group in groups['AutoScalingGroups']:
  group_name = group['AutoScalingGroupName']
  if pattern.match(group_name):
    print group_name
    if size == 'None':
      response1 = client.update_auto_scaling_group(
                   AutoScalingGroupName=group_name,
                   MinSize=0
                 )
      response2 = client.set_desired_capacity(
                   AutoScalingGroupName=group_name,
                   DesiredCapacity=0
                 )
    elif size == 'Default':
      for key in defaults:
        if key in group_name:
          response1 = client.update_auto_scaling_group(
                        AutoScalingGroupName=group_name,
                        MinSize=defaults[key]
                      )
          response2 = client.set_desired_capacity(
                       AutoScalingGroupName=group_name,
                       DesiredCapacity=defaults[key]
                     )

    pp.pprint(response1)
    pp.pprint(response2)
