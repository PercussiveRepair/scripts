#!/usr/bin/python
import csv
import sys
import boto.dynamodb2
from boto.dynamodb2.fields import HashKey
from boto.dynamodb2.table import Table

def main():
    
    conn = boto.dynamodb.connect_to_region('eu-west-1',
        aws_access_key_id='',
        aws_secret_access_key='')
    print "connect to DynamoDB"
    table = Table('Governess-user-domain-beta', connection=conn) 
    print "connect to the table"
    
    with open ("betaUsers.csv",'rw') as csvfile:
        reader = csv.reader(csvfile)
        for user, userdomain, smsdomain in reader:
            
            print user + ' ' + userdomain + ' ' + smsdomain
            
            table.put_item(data={
                'UsedID': user,
                'UserDomain': userdomain,
                'SmsDomain': smsdomain,
                })  
if __name__ == "__main__":
    main()
