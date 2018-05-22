#!/usr/bin/python

from boto.dynamodb2.layer1 import DynamoDBConnection
from boto.dynamodb2.table import Table
from boto.dynamodb2.items import Item
import boto
import csv

userSessions = Table('Governess-user-domain-prod')

allUsers = userSessions.scan()
isopUsers=[]
hiveUsers=[]
count = 0

with open('hiveusers.csv', 'rb') as csvfile:
  reader = csv.reader(csvfile, delimiter=',', quotechar='"')
  for user in allUsers:
    if user['UserDomain'] == 'https://api-prod-isop.bgchprod.info:443/':
      userid = user['UserID'].lower()
      for row in reader:
            username = row[0].lower()
   #         print username
            if userid == username:
              print userid
    count +=1
print count
