#! /usr/bin/python

# gets instance events and posts to slack

import boto3
from slackclient import SlackClient
from tabulate import tabulate

token = '<%= @slack_token %>'
creds = open('/Users/jayharrison/.aws/credentials', 'r')
regions = ['us-east-1']
filters = [{ 'Name': 'event.code', 'Values': [ 'instance-reboot','system-reboot','system-maintenance','instance-retirement','instance-stop']}]
instance_count = 0
instanceevents = []
instanceevents2 = []

# get instance maintenance data
try:
  for line in creds:
    if line.startswith('['):
      profile=line[1:-2]
      # print profile
      for region in regions:
        boto3.setup_default_session(profile_name=profile, region_name=region)
        client = boto3.client('health')
        for status in client.describe_events():
          print(status)


#           instance        = client.describe_instances(InstanceIds=[status['InstanceId']])
#           instancename    = ''
#           instancerole    = ''
#           instanceproduct = ''
#           if 'Tags' in instance['Reservations'][0]['Instances'][0]:
#             for tag in instance['Reservations'][0]['Instances'][0]['Tags']:
#               if tag['Key'] == 'Name':
#                 instancename = tag['Value']
#               elif tag['Key'] == 'role':
#                 instancerole = tag['Value']
#               elif tag['Key'] == 'product':
#                 instanceproduct = tag['Value']
#           date = str(status['Events'][0]['NotBefore'])[:-15]
#           description = str(status['Events'][0]['Description']).replace('The instance is running on ', '')
#           action = str(status['Events'][0]['Code']).replace('system-', '').replace('instance-', '')
  
#           instanceinfo = { 'Account': profile, 'InstanceId': status['InstanceId'], 'Action': action, 'Status': description, 'Name': instancename, 'Region/AZ': status['AvailabilityZone'], 'DueDate': date}
#           instance_count += 1
#           if instance_count < 18:
#             instanceevents.append(instanceinfo)
#           else:
#             instanceevents2.append(instanceinfo)

except Exception,e: 
  print str(e)
  pass

# # assemble slack message  

# if instanceevents:
#   table = tabulate(instanceevents, headers='keys') 
#   sc = SlackClient(token)
#   print sc.api_call(
#           "chat.postMessage", channel="<%= @slack_channel %>", text='``` ' + table + ' ```',
#           username='AWS Instance Events', icon_emoji=':bomb:'
#   )
# if instanceevents2:
#   table = tabulate(instanceevents2, headers='keys') 
#   sc = SlackClient(token)
#   print sc.api_call(
#           "chat.postMessage", channel="<%= @slack_channel %>", text='``` ' + table + ' ```',
#           username='AWS Instance Events', icon_emoji=':bomb:'
#   )