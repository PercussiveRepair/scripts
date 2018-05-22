#!/usr/bin/env python

import json
from os import environ

import boto3
boto3.setup_default_session( region_name='eu-west-1', profile_name='connectedboiler')

AWS_S3_BUCKET= "cbprod-cloudtrail"
AWS_SQS_URL = "https://sqs.eu-west-1.amazonaws.com/116645666073/traildash"

bucket = boto3.resource('s3').Bucket(AWS_S3_BUCKET)
queue = boto3.resource('sqs').Queue(AWS_SQS_URL)


items_queued = 0
for item in bucket.objects.all():
    if not item.key.endswith('.json.gz'):
        continue

    queue.send_message(
        MessageBody=json.dumps({
            'Message': json.dumps({
                's3Bucket': AWS_S3_BUCKET,
                's3ObjectKey': [item.key]
            })
        })
    )
    items_queued += 1

print('Done! {} items were backfilled'.format(items_queued))
