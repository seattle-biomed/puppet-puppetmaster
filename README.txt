puppetmaster

A puppet module to bootstrap a puppetmaster; written to be run from
"puppet apply".

Example usage:

> /usr/bin/puppet module install cprice404-inifile
> /usr/bin/sudo /usr/bin/puppet apply --modulepath=~/.puppet/modules \
    puppetmaster.pp -e "include puppetmaster"
