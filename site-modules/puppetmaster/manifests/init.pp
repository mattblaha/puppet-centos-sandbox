class puppetmaster(
  String $allow_puppetboard = 'accept',
){

  require epel
  require ::scl

  # Configure puppetdb and its underlying database
  class { 'puppetdb': 
  }->
  # Configure the Puppet master to use puppetdb
  ini_setting { "sample setting":
  ensure  => present,
  path    => '/etc/puppetlabs/puppet/puppet.conf',
  section => 'master',
  setting => 'reports',
  value   => 'store,puppetdb',
  }->
  class { 'puppetdb::master::config': }

  $mod_wsgi_package_name = 'rh-python36-mod_wsgi'

  package { ['python3', 'python3-pip', 'python3-devel', 'python36-virtualenv']:
    ensure => present,
  }

  # configure apache
  class { 'apache':
    purge_configs => false,
    mpm_module    => 'prefork',
    default_vhost => false,
    default_mods  => false,
  }

  # configure mod_wsgi for python3
  class { 'apache::mod::wsgi':
    mod_path           => 'modules/mod_rh-python36-wsgi.so',
    package_name       => $mod_wsgi_package_name,
    wsgi_socket_prefix => '/var/run/wsgi',
  }

  # create symlinks from the isolated Red Hat directory into the
  # standard Apache paths so that it can pick up the module and config
  file { '/etc/httpd/conf.modules.d/10-rh-python36-wsgi.conf':
    ensure  => 'link',
    target  => '/opt/rh/httpd24/root/etc/httpd/conf.modules.d/10-rh-python36-wsgi.conf',
    require => Package[$mod_wsgi_package_name],
  }
  file { '/usr/lib64/httpd/modules/mod_rh-python36-wsgi.so':
    ensure  => 'link',
    target  => '/opt/rh/httpd24/root/usr/lib64/httpd/modules/mod_rh-python36-wsgi.so',
    require => Package[$mod_wsgi_package_name],
  }
  file { '/etc/httpd/conf/mime.types':
    ensure  => 'link',
    target  => '/etc/mime.types',
    require => Package[$mod_wsgi_package_name],
  }

  package { 'git':
    ensure => present,
    }->
  file { '/bin/virtualenv':
    ensure  => 'link',
    target  => '/bin/virtualenv-3',
    require => Package['python36-virtualenv'],
  }->
  class { 'puppetboard':
    # use python3 when setting up the virtualenv for puppetboard
    virtualenv_version => '3',
    # specify other parameters here
    default_environment => '*',
  }


  # Access Puppetboard through pboard.example.com, port 8888
  class { 'puppetboard::apache::vhost':
    vhost_name => 'puppetboard.example.com',
    port => 80,
  }

  # the puppetdb class is going to configure iptables, so we have to allow
  # the puppetserver to listen explicitly
  firewall { '80 allow puppetboard':
    dport  => 80,
    proto  => 'tcp',
    action => $allow_puppetboard,
  }

  firewall { '8140 allow puppetserver':
    dport  => 8140,
    proto  => 'tcp',
    action => 'accept',
  }
}

