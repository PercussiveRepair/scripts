import sys
import ldap


Server = "ldap://ldap-server-name"
DN, Secret, un = sys.argv[1:4]

Base = "dc=xxx,dc=co,dc=uk"
Filter = "(&(objectClass=user)(sAMAccountName="+un+"))"
Attrs = ["displayName"]

l = ldap.initialize(Server)
l.protocol_version = 3
l.set_option(ldap.OPT_REFERRALS, 0)
print l.simple_bind_s(DN, Secret)

r = l.search(Base, ldap.SCOPE_SUBTREE, Filter, Attrs)
Type,user = l.result(r,60)
Name,Attrs = user[0]
if hasattr(Attrs, 'has_key') and Attrs.has_key('displayName'):
  displayName = Attrs['displayName'][0]
  print displayName

sys.exit()
