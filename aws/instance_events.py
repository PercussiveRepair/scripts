#! /usr/bin/python

# gets instance events and posts to slack

import boto3
from slackclient import SlackClient
from tabulate import tabulate

token = ''
creds = open('/Users/jayharrison/.aws/credentials', 'r')
regions = ['eu-west-1', 'us-east-1']
filters = [{ 'Name': 'event.code', 'Values': [ 'instance-reboot','system-reboot','system-maintenance','instance-retirement','instance-stop']}]
instance_count = 0
instanceevents = []

# get instance maintenance data
try:
  for line in creds:
    if line.startswith('['):
      profile=line[1:-2]
      # print profile
      for region in regions:
        boto3.setup_default_session(profile_name=profile, region_name=region)
        client = boto3.client('ec2')
        for status in client.describe_instance_status(Filters=filters)['InstanceStatuses']:
          instance = client.describe_instances(InstanceIds=[status['InstanceId']])
          instancename = ''
          instancerole = ''
          instanceproduct = ''
          if 'Tags' in instance['Reservations'][0]['Instances'][0]:
            for tag in instance['Reservations'][0]['Instances'][0]['Tags']:
              if tag['Key'] == 'Name':
                instancename = tag['Value']
              elif tag['Key'] == 'role':
                instancerole = tag['Value']
              elif tag['Key'] == 'product':
                instanceproduct = tag['Value']
          date = str(status['Events'][0]['NotBefore'])[:-15]
          description = str(status['Events'][0]['Description']).replace('The instance is running on ', '')
          action = str(status['Events'][0]['Code']).replace('system-', '').replace('instance-', '')
  
          instanceinfo = { 'Account': profile, 'InstanceId': status['InstanceId'], 'Action': action, 'Status': description, 'Name': instancename, 'Region/AZ': status['AvailabilityZone'], 'DueDate': date}
          instanceevents.append(instanceinfo)

except Exception,e: 
  print str(e)
  pass

# assemble slack message  
if instanceevents:
  items, chunk = instanceevents, 18
  for start in xrange(0,len(items),chunk):
      end = start + chunk
      table = tabulate(items[start:end], headers='keys') 
      sc = SlackClient(token)
      print sc.api_call(
            "chat.postMessage", channel="@jay.harrison", text='``` ' + table + ' ```',
            username='AWS Instance Events', icon_emoji=':bomb:'
            )
