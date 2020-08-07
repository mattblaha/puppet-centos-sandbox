class puppet_agent {

  ini_setting { "puppet_server":
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    section => 'agent',
    setting => 'server',
    value   => $server_facts[servername],
    notify  => Service['puppet'],
  }

  ini_setting { "puppet_environment":
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    section => 'agent',
    setting => 'environment',
    value   => $server_facts[environment],
    notify  => Service['puppet'],
  }

  ini_setting { "puppet_splay":
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    section => 'agent',
    setting => 'splay',
    value   => 'true',
    notify  => Service['puppet'],
  }

  service { 'puppet':
    ensure => running,
    enable => true,
  }

}
