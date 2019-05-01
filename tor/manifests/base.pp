# basic management of resources for tor
class tor::base {
  package {'tor':
    ensure => installed,
  }
  if $facts['osfamily'] == 'Debian' {
    package {'tor-geoipdb':
      ensure => installed,
      before => Service['tor'],
    }
  }

  service { 'tor':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => Package['tor'],
  }
}
