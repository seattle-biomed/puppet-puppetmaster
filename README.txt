puppetmaster

A puppet module to bootstrap a puppetmaster; written to be run from
"puppet apply".  Originally developed against Ubuntu 12.04 and the PuppetLabs
apt repos; initial support for Canonical's packaging of the Puppetmaster
courtesy of preflightsiren / puppet-puppetmaster.

Example usage:

> puppet module install cprice404-inifile
> git clone https://github.com/seattle-biomed/puppet-puppetmaster.git
> mv puppet-puppetmaster ~/.puppet/modules/puppetmaster
> sudo puppet apply --modulepath=~/.puppet/modules -e "include puppetmaster"

or 

> sudo puppet apply --modulepath=~/.puppet/modules -e "class { puppetmaster: hiera_gpg => true }"
