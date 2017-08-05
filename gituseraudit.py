#! /usr/bin/python

from github import Github
import time
import requests
import csv

updated = time.strftime("%c")
f = open('users.html','w')
token = ''
service_accounts = []

with open('ADusers2.csv', 'rb') as csvfile:
  readfile = csv.reader(csvfile)
  adusers = {}
  for row in readfile:
    adusers[row[1]] = [row[2], row[0]]
print adusers

#delay if rate limited
rate_url = 'https://api.github.com/rate_limit?access_token=' + token
rate_limit = requests.get(rate_url).json()
if rate_limit['rate']['remaining'] < 1000:
  print "Rate Limited- sleeping"
  time.sleep(600)

# create github object
g = Github(login_or_token=token)

print "get teams"
# get team memberships
team_ids = {}
for teams in g.get_organization("ConnectedHomes").get_teams():
  team_ids[teams.name] = teams.id
teams = []
for team,team_id in team_ids.iteritems():
  for team_member in g.get_organization("ConnectedHomes").get_team(team_id).get_members():
    teams.append({'team': team, 'member': team_member.login})

message = """<html>
<head> <script src="sorttable.js"></script><script src="searchtable.js"></script><link rel="stylesheet" href="//cdn.rawgit.com/yahoo/pure-release/v0.6.0/pure-min.css"></head>
<body><h2>GitHub Users</h2>
<p>Updated {updated} UTC</p>
<form class="pure-form"><input type="search" class="light-table-filter" data-table="order-table" placeholder="Filter"></form>""".format(updated=updated)

print "get members"
#create members list
members = []
service_account_count = 0
twofadis_users_only = 0
for user in g.get_organization("ConnectedHomes").get_members():
  user_teams = []
  for team in teams:
    if team['member'] == user.login:
      user_teams.append(team['team'])
  #check for user in list of AD users
  aduser = 'not found'
  adenabled = 'false'
  if user.name:
    if user.name.lower() in adusers.keys():
      aduser = user.name
      adenabled = adusers[user.name.lower()][1]

  member = {'name': user.name, 'login': user.login, 'email': user.email, 'teams': user_teams, 'aduserinfo': aduser, 'aduseractive': adenabled}
  members.append(member)
  if user.login in service_accounts:
    service_account_count += 1

print "get 2fa"
#get 2fa disabled users
twofadis = []
for user in g.get_organization("ConnectedHomes").get_members(filter_='2fa_disabled'):
  dis = user.login
  twofadis.append(dis)
  if user.login not in service_accounts:
   twofadis_users_only +=1

#assemble page
message += '<p style="background-color: #ef9a9a;">Members with 2FA disabled (excluding Service Accounts): ' + str(twofadis_users_only) + ' out of ' + str(len(members)) + ' total users</p>'
message += '<p style="background-color: #9FA8DA;">Service Accounts: ' + str(service_account_count) + '</p>'
message += '<table class="sortable pure-table order-table"><tr><th>User ID</th><th>Name</th><th>Public Email</th><th>2FA Enabled?</th><th>Service Account?</th><th>Teams</th><th>AD User</th><th>AD User Active</th></tr>'
print "making page"
for m in members:
  name = str(m['name'].encode('utf-8')) if m['name'] != None else ''
  login = str(m['login'].encode('utf-8')) if m['login'] != None else ''
  email = str(m['email'].encode('utf-8')) if m['email'] != None else ''
  teams = str(', '.join(m['teams']))
  twofaen = 'No' if login in twofadis else 'Yes'
  service_account = 'Yes' if login in service_accounts else 'No'
  aduserinfo = m['aduserinfo']
  aduseractive = m['aduseractive']
  bgcolor = '#C5E1A5'
  if login not in twofadis and m['name'] == None and m['email'] == None:
      bgcolor = '#FFCC80'
  if login in twofadis:
    bgcolor = '#ef9a9a'
  if login in service_accounts:
    bgcolor = '#9FA8DA'

  message += """<tr bgcolor = {bgcolor}><td><a href="https://github.com/orgs/ConnectedHomes/people/{login}">{login}</a></td><td>{name}</td><td>{email}</td><td>{twofaen}</td><td>{service_account}</td><td>{teams}</td><td>{aduser}</td><td>{aduseractive}</td></tr>""".format(bgcolor=bgcolor,login=login,name=name,email=email,twofaen=twofaen,service_account=service_account,teams=teams,aduser=aduserinfo,aduseractive=aduseractive)

message += '</table> </body> </html>'

f.write(message)
f.close()
