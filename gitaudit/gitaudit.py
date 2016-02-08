#! /usr/bin/python

# github org repo gather script

import requests
import pprint
import json

f = open('index.html','w')

token = ''
pages = 8 #number of repos / 100

message = """<html>
<head> <script src="sorttable.js"></script></head>
<body><h2>GitHub Repos</h2>
<table border="1" class="sortable"><tr><th>name</th><th>created</th><th>last_updated</th><th>Issues</th><th>Wiki</th><th>size kB</th></tr>"""

for i in range(pages):
  url = 'https://api.github.com/orgs/ConnectedHomes/repos?page=' + str(i) + '&per_page=100&access_token=' + token
  response = requests.get(url)

  for repo in response.json():

    message += '<tr><td><a target="_blank" href="' + repo['html_url'] + '">' + repo['name'] + '</a></td><td>' + repo['created_at'] + '</td><td>' + repo['pushed_at'] + '</td><td>' + str(repo['has_issues']) + '</td><td>' + str(repo['has_pages']) + '</td><td>' + str(repo['size']) + '</td></tr>'


f.write(message)
f.close()
