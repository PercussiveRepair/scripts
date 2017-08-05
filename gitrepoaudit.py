#! /usr/bin/python

# github org repo gather script

from github import Github
import requests
import json
import time

updated = time.strftime("%c")
token = ''
repo_count = 0
totalsize=0

#delay if rate limited
rate_url = 'https://api.github.com/rate_limit?access_token=' + token
rate_limit = requests.get(rate_url).json()
if rate_limit['rate']['remaining'] < 1000:
  print "Rate Limited- sleeping"
  time.sleep(600)

g = Github(login_or_token=token)

#get repo count
repo_count = g.get_organization("ConnectedHomes").total_private_repos

message = """<html>
<head> <script src="../sorttable.js"></script><script src="../searchtable.js"></script><link rel="stylesheet" href="//cdn.jsdelivr.net/pure/0.6.0/pure-min.css"></head>
<body><h2>GitHub Repos</h2>
<p>Updated: {updated}</p>
<p>Number of private repos: {repo_count}</p>
<form class="pure-form"><input type="search" class="light-table-filter" data-table="order-table" placeholder="Filter"></form>
<table class="sortable order-table pure-table"><thead><tr><th>Name</th><th>Created</th><th>Last Updated</th><th>Issues</th><th>Wiki</th><th>Size kB</th><th>Private?</th><th>Fork?</th></tr></thead><tbody>""".format(updated=updated,repo_count=repo_count)

for repo in g.get_organization("ConnectedHomes").get_repos():
  repo_count += 1
  if repo.description and "public repo" in repo.description.lower():
    bgcolor = '#9FA8DA'
  elif not repo.private and not repo.fork:
    bgcolor = '#FFCC80'
  else:
    bgcolor = '#FFFFFF'
  message += "<tr bgcolor = {bgcolor}><td><a target='_blank' href={url}>{name}</a></td><td>{created_at}</td><td>{pushed_at}</td><td>{has_issues}</td><td>{has_wiki}</td><td>{size}</td><td>{private}</td><td>{fork}</td></tr>".format(bgcolor=bgcolor, url=repo.html_url, name=repo.name, created_at=str(repo.created_at), pushed_at=str(repo.pushed_at), has_issues=str(repo.has_issues), has_wiki=str(repo.has_wiki), size=str(repo.size), private=str(repo.private), fork=str(repo.fork))
  totalsize+=repo.size

message += "</tbody></table>"
message += "<table><tr><td bgcolor = #9FA8DA>Verified Public Repo</td><td bgcolor = #FFCC80>Unintentionally Public Repo?</td></tr></table>"
message += "<p>Total Size: {}</p>".format(totalsize)
f = open('index.html','w')
f.write(message)
f.close()
