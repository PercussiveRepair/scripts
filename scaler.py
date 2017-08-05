#! /usr/bin/python

# aws oma/edge scaler - runs on the orchestrator

import boto3
import urllib
import json
import logging

isop_access = ''
isop_key = ''
env = 'prod'
map_url = 'http://localhost:8083/mapping'

logging.basicConfig(filename='scaler.log',format='%(asctime)s %(levelname)s:%(message)s',level=logging.INFO)

def get_rabbits_map(map_url):
  """ get rabbits from orchestrator map """

  response = urllib.urlopen(map_url)
  data = json.loads(response.read())
  rabbits = len(data['edgeRabbitsNotConnected']) + len(data['edgeRabbitConnectedToUnknownConsumer']) + len(data['edgeRabbitsConnected'])
  return rabbits

def get_unused_omas(map_url):
  """ get unused omas from orchestrator map """

  response = urllib.urlopen(map_url)
  data = json.loads(response.read())
  rabbits = len(data['edgeRabbitsNotConnected']) + len(data['edgeRabbitConnectedToUnknownConsumer']) + len(data['edgeRabbitsConnected'])
  return rabbits

def get_asgs( key = None, secret = None ):
  """ get autoscaling groups """

  if key:
    boto3.setup_default_session( region_name='eu-west-1', aws_access_key_id=key, aws_secret_access_key=secret )
  else:
    boto3.setup_default_session( region_name='eu-west-1' )
  client = boto3.client('autoscaling')
  groups = client.describe_auto_scaling_groups(
             MaxRecords=100
           )
  return groups['AutoScalingGroups']


# get edge rabbit tier size
for group in get_asgs( isop_access, isop_key ):
  if 'Edge' in group['AutoScalingGroupName']:
    logging.info('Current group size: ' + group['AutoScalingGroupName'] + ' ' + str(group['DesiredCapacity']))
    rabbits += group['DesiredCapacity']

# get oma tier size
for group in get_asgs():
  if env in group['AutoScalingGroupName'] and 'oma' in group['AutoScalingGroupName']:
    logging.info('Current group size: ' + group['AutoScalingGroupName'] + ' ' + str(group['DesiredCapacity']))
    oma_group = group['AutoScalingGroupName']
    omas = group['DesiredCapacity']

#group correct size check
omas_required = rabbits + 5
if get_rabbits_map(map_url) != rabbits:
  logging.warn('Rabbit mismatch - orchestrator mapping and edge rabbit tier size do not match')
elif rabbits > omas:
  logging.info('Scaling up OMA tier')
  logging.info('OMAs required: ' + str(omas_required))
  response1 = client.update_auto_scaling_group(
                AutoScalingGroupName=oma_group,
                MinSize=omas_required
              )
  response2 = client.set_desired_capacity(
                AutoScalingGroupName=oma_group,
                DesiredCapacity=omas_required
              )
  logging.info('Scaling started')
elif omas > omas_required:
  logging.info('Too many OMAs!')
else:
  logging.info('Tiers correct')
