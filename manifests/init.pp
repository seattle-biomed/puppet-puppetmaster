# = Class: puppetmaster
#
# Bootstrap a puppetmaster/mod_passenger server
#
# Written with the intent of being run from puppet apply.
#
# == Parameters:
#  - master_name - hostname of puppetmaster, for puppet.conf
#
# == Actions:
#  - Install puppetmaster/mod_passenger packages
#  - Fix puppetmaster/passenger configuration
#  - Configure puppet.conf
#  - Set reports directory permissions
#  - Configure hiera
#
# == Authors:
#  - Andrew Leonard <andy.leonard@sbri.org>
#
# == Requires:
#  - cprice404-inifile
#
# == Sample Usage:
#
# puppet apply --modulepath=~/.puppet/modules -e "include puppetmaster"
#
# == Copyright:
#
# Copyright Seattle Biomedical Research Institute, 2012
#
class puppetmaster($master_name = $::fqdn) {

  $pkgs = [ 'puppet-common', 'puppetmaster-passenger' ]

  package { $pkgs:
    ensure => present,
  }

  # Fix puppetmaster/passenger configuration in 3.0.0 - see bug at
  # <http://projects.puppetlabs.com/issues/16769>:
  file { '/etc/apache2/sites-available/puppetmaster':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('puppetmaster/puppetmaster.erb'),
    require => Package['puppetmaster-passenger'],
  }

  if ($master_name == '') {
    fail('Puppetmaster name must be set; is fqdn fact not populated?')
  } else {
    # Tested against cprice404/inifile 0.0.3:
    ini_setting { 'puppetmaster':
      ensure  => present,
      path    => '/etc/puppet/puppet.conf',
      section => 'main',
      setting => 'server',
      value   => $master_name,
      require => Package['puppet-common'],
    }
  }

  # /var/lib/puppet/reports comes from deb root:root, causes Passenger to fail:
  file { '/var/lib/puppet/reports':
    ensure  => directory,
    owner   => 'puppet',
    require => Package['puppetmaster-passenger'],
  }

  # Configure hiera:

  file { '/etc/hiera.yaml':
    ensure  => present,
    content => template('puppetmaster/hiera.yaml.erb'),
  }

  file { '/etc/puppet/hiera.yaml':
    ensure => link,
    target => '/etc/hiera.yaml',
  }

  file { '/etc/hiera':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
}
