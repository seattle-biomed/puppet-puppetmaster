# = Class: puppetmaster
#
# Bootstrap a puppetmaster/mod_passenger server
#
# Written with the intent of being run from puppet apply.
#
# == Parameters: (none)
#
# == Actions:
#  - Install puppetmaster/mod_passenger packages
#  - Configure puppet.conf
#  - Set reports directory permissions
#
# == Authors:
#  - Andrew Leonard <andy.leonard@sbri.org>
#
# == Requires:
#  - cprice404-inifile
#
# == Sample Usage:
#
# puppet apply --modulepath=~/.puppet/modules puppetmaster.pp \
#  -e "include puppetmaster"
#
# == Copyright:
#
# Copyright Seattle Biomedical Research Institute, 2012
#
class puppetmaster {

  $pkgs = [ 'puppet-common', 'puppetmaster-passenger' ]

  package { $pkgs:
    ensure => present,
  }

  # Tested against cprice404/inifile 0.0.3:
  ini_setting { 'puppetmaster':
    ensure  => present,
    path    => '/etc/puppet/puppet.conf',
    section => 'main',
    setting => 'server',
    value   => $fqdn,
    require => Package['puppet-common'],
  }

  # /var/lib/puppet/reports comes from deb root:root, causes Passenger to fail:
  file { '/var/lib/puppet/reports':
    ensure  => directory,
    owner   => 'puppet',
    require => Package['puppetmaster-passenger'],
  }
  
}
