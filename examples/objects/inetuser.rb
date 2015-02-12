require 'objects/group'

class InetUser < ActiveLdap::Base
  ldap_mapping :dn_attribute => 'uid', :prefix => 'ou=People',
               :classes => ['inetOrgPerson']

end
