#! /usr/bin/python

# github org repo gather script

import requests
import json

token = ''
pages = 8 #number of repos / 100
repo_count = 0

repos = []

for i in range(pages):
  url = 'https://api.github.com/orgs/ConnectedHomes/teams?page=' + str(i) + '&access_token=' + token
  response = requests.get(url)
  print json.dumps(response.json(), sort_keys=True, indent=4, separators=(',', ': '))



