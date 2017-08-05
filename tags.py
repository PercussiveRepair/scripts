#!/usr/bin/env python
import boto.ec2, os, json, csv
# key 
AWS_KEY_ID=""
AWS_ACCESS_KEY=""
# Change this to point to appropriate region
AWS_REGION="eu-west-1"
# Change this to pull info for the specific nodes with the desired tag
FLTR_ROLE="services"
conn = boto.ec2.connect_to_region(AWS_REGION, aws_access_key_id=AWS_KEY_ID, aws_secret_access_key=AWS_ACCESS_KEY)
#reservations=conn.get_all_instances(filters={"tag:Role": FLTR_ROLE});
reservations=conn.get_all_instances();

TAGS = {}
for res in reservations:
  for inst in res.instances:
    instname = str(inst).replace("Instance:", "")
    with open('instances.csv', 'rU') as csvfile:
      reader = csv.reader(csvfile, delimiter=',')
      for row in reader:
        if row[0] == instname:
          print instname , inst.tags
