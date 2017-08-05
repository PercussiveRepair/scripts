#! /usr/bin/python

from github import Github
import time
import requests
import csv

updated = time.strftime("%c")
token = ''
service_accounts = []

#delay if rate limited
rate_url = 'https://api.github.com/rate_limit?access_token=' + token
rate_limit = requests.get(rate_url).json()
if rate_limit['rate']['remaining'] < 1000:
  print "Rate Limited- sleeping"
  time.sleep(600)

g = Github(login_or_token=token)

#find offenders
twofadis = []
for user in g.get_organization("ConnectedHomes").get_members(filter_='2fa_disabled'):
  dis = {'name': user.name, 'login': user.login, 'email': user.email}
  if user.login not in service_accounts:
    twofadis.append(dis)
    # removed = g.get_organization("ConnectedHomes").remove_from_members(user)

with open('usersremoved.csv', 'a') as csvfile:
  users = csv.writer(csvfile)

  for m in twofadis:
    name = str(m['name'].encode('utf-8')) if m['name'] != None else ''
    login = str(m['login'].encode('utf-8')) if m['login'] != None else ''
    email = str(m['email'].encode('utf-8')) if m['email'] != None else ''

    users.writerow([login, name, email, updated])
 

#create html report
fhtml = open('usersremoved.html','w')

page = """<html>
<head> <script src="sorttable.js"></script><link rel="stylesheet" href="//cdn.rawgit.com/yahoo/pure-release/v0.6.0/pure-min.css"></head>
<body><h2>GitHub Users Removed</h2>
<p>Updated {updated}</p>""".format(updated=updated)

page += '<table class="sortable pure-table"><tr><th>User ID</th><th>Name</th><th>Public Email</th><th>Time removed</th></tr>'

with open('usersremoved.csv', 'r') as csvfile:
  offenders = csv.reader(csvfile)
  for row in offenders:
    page += """<tr><td><a href="https://github.com/orgs/ConnectedHomes/people/{login}">{login}</a></td><td>{name}</td><td>{email}</td><td>{removed}</td></tr>""".format(login=row[0],name=row[1],email=row[2],removed=row[3])

page += '</table> </body> </html>'

fhtml.write(page)
fhtml.close()
