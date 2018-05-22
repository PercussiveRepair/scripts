#!/usr/bin/python

from boto.dynamodb2.layer1 import DynamoDBConnection
from boto.dynamodb2.table import Table
from boto.dynamodb2.items import Item
import boto

userSessions = Table('Governess-user-domain-prod')
import csv
for userName in open('newToISOP.csv', 'rb'):
     userName=userName.lower().strip()
     print userName
     user = userSessions.get_item(UserID=userName)
     user['UserDomain'] = 'https://api-prod-isop.bgchprod.info:443/'
     user['SmsDomain']='https://receive-sms-prod.bgchprod.info:443/'
     user['UserID']=userName
     user.save()
exit()
