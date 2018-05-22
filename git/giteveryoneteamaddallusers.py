#! /usr/bin/python

# github org add all except service users to everyone team

from github import Github
import requests
import time

token = ''
service_accounts = []


#delay if rate limited
rate_url = 'https://api.github.com/rate_limit?access_token=' + token
rate_limit = requests.get(rate_url).json()
if rate_limit['rate']['remaining'] < 1000:
  print "Rate Limited- sleeping"
  time.sleep(600)

g = Github(login_or_token=token)
for user in g.get_organization("ConnectedHomes").get_members():
    if user.login not in service_accounts:
      g.get_organization("ConnectedHomes").get_team(2388051).add_to_members(user)
      print user.login + ' added'
