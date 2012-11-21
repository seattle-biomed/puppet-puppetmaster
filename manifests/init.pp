# = Class: puppetmaster
#
# Bootstrap a puppetmaster/mod_passenger server
#
# Written with the intent of being run from puppet apply.
#
# == Parameters:
#  - hiera_gpg - boolean, indicating whether or not to install hiera-gpg
#  - hiera_gpg_version - version of hiera_gpg to download
#  - master_name - hostname of puppetmaster, for puppet.conf
#
# == Actions:
#  - Install puppetmaster/mod_passenger packages
#  - Fix puppetmaster/passenger configuration
#  - Configure puppet.conf
#  - Set reports directory permissions
#  - Configure hiera
#  - Optionally, install hiera-gpg
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
class puppetmaster(
  $hiera_gpg = false,
  $hiera_gpg_version = 'master', # N.B. 1.0.3 and earlier broken w/hiera 1.0.0
  $master_name = $::fqdn
  ) {

  $pkgs = [ 'apache2.2-common', 'puppet-common', 'puppetmaster-passenger' ]

  package { $pkgs:
    ensure => present,
  }

  # Disable default Apache site:
  file { '/etc/apache2/sites-enabled/000-default':
    ensure  => absent,
    notify  => Service['apache2'],
    require => Package['apache2.2-common'],
  }

  service { 'apache2':
    enable  => true,
    require => Package['apache2.2-common'],
  }

  # Fix puppetmaster/passenger configuration in 3.0.0 - see bug at
  # <http://projects.puppetlabs.com/issues/16769>:
  if $::puppetversion == '3.0.0' {
    file { '/etc/apache2/sites-available/puppetmaster':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      content => template('puppetmaster/puppetmaster.erb'),
      require => Package['puppetmaster-passenger'],
    }
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

  file { '/etc/puppet/hiera.yaml':
    ensure  => present,
    content => template('puppetmaster/hiera.yaml.erb'),
  }

  file { '/etc/hiera.yaml':
    ensure => link,
    target => '/etc/puppet/hiera.yaml',
  }

  file { '/etc/hiera':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  if $hiera_gpg {

    file { '/etc/hiera-gpg':
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }

    package { 'ruby-gpgme': ensure => present }

    exec { 'download hiera-gpg':
      command => "/usr/bin/wget https://raw.github.com/crayfishx/hiera-gpg/${hiera_gpg_version}/lib/hiera/backend/gpg_backend.rb",
      creates => '/usr/lib/ruby/vendor_ruby/hiera/backend/gpg_backend.rb',
      cwd     => '/usr/lib/ruby/vendor_ruby/hiera/backend/',
      require => Package['puppetmaster-passenger'], # Pulls in hiera
    }
  }
}
