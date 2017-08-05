#! /usr/bin/python

# github org repo add to read only team

import requests
import json
import time
import math

token = ''
repos = []

#delay if rate limited
rate_url = 'https://api.github.com/rate_limit?access_token=' + token
rate_limit = requests.get(rate_url).json()
if rate_limit['rate']['remaining'] < 1000:
  print "Rate Limited- sleeping"
  time.sleep(600)

#get repo and hence page count
repo_count_url = 'https://api.github.com/orgs/ConnectedHomes?access_token=' + token
repo_count_response = requests.get(repo_count_url).json()
pages = int(math.ceil(repo_count_response['total_private_repos']/100.0) +2)
print pages

#get repos
for i in range(pages):
  url = 'https://api.github.com/orgs/ConnectedHomes/repos?page=' + str(i) + '&per_page=100&access_token=' + token
  response = requests.get(url)

  for repo in response.json():
    if repo not in repos:
      repos.append(repo)

#add repos to read-only-all team
for repo in repos:
  print(repo['name'])
  url_put = 'https://api.github.com/teams/2196270/repos/ConnectedHomes/' + repo['name'] + '?permission=pull&access_token=' + token
  r = requests.put(url_put)
  print(r)
