# == Class: bst
#
# Full description of class bst here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { bst:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2014 Your name here, unless otherwise noted.
#
class bst ( 
  $szDnsmasqProcessOwnerName = 'nobody',
  $szWebProcessOwnerName = 'lighttpd',
  $szIpAddressForSupportingKickStart = hiera( 'IpAddressForSupportingKickStart' ),
  $szTftpBaseDirectory = '/var/tftp',
  $szKickStartBaseDirectory = '/var/ks',
  $szKickStartImageDirectory = "$szKickStartBaseDirectory/images"
) {

$szBootServerVarDirectory = "/var/boot_server_tools"
$szTmpMountPoint = "$szBootServerVarDirectory/tmp"

file { "$szBootServerVarDirectory":
  ensure => directory,
}

file { "$szTmpMountPoint":
  ensure  => directory,
  require => File [ "$szBootServerVarDirectory" ],
}

file { '/etc/config_boot_server_tool.yaml':
  ensure  => file,
  content => template('/etc/puppet/modules/bst/templates/config_boot_server_tool_yaml.erb'),
}


package { 'perl-Text-Template':
  ensure => present,
}

package { 'perl-Data-Dumper':
  ensure => present,
}

package { 'perl-YAML-LibYAML':
  ensure => present,
}

package { 'fuseiso':
  ensure => present,
}

}
