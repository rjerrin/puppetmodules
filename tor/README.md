# tor

#### Table of Contents

* [Overview](#overview)
  * [Upgrade Notice](#upgrade-notice)
* [Dependencies](#dependencies)
* [Usage](#usage)
  * [Installing tor](#installing-tor)
  * [Configuring SOCKS](#configuring-socks)
  * [Installing torsocks](#installing-torsocks)
  * [Configuring relays](#configuring-relays)
  * [Configuring the control](#configuring-control)
  * [Configuring onion services](#configuring-onion-services)
  * [Configuring directories](#configuring-directories)
  * [Configuring exit policies](#configuring-exit-policies)
  * [Configuring transport plugins](#configuring-transport-plugins)
* [Functions](#functions)
* [Munin](#munin)

# Overview<a name="overview"></a>

This module tries to manage tor, making sure it is installed, running, has
munin graphs if desired and allows for configuration of relays, onion services,
exit policies, etc.

## Upgrade Notice<a name="upgrade-notice"></a>

 * All of the `listen_address` variables have been deprecated, since they have
   been deprecated in tor since 0.2.3.x-alpha. Please read the new tor man page
   if you were using those variables.

 * Previously, if you did not set the `$outbound_bindaddress` variable, it was
   being automatically set to the `$listen_address variable`. Now this is not
   being done and instead you will need to set the `$outbound_bindaddress`
   explicitly for it to be set.

 * The `tor::relay{}` variables `$bandwidth_rate` and `$bandwidth_burst` were
   previously used for the tor configuration variables `RelayBandwidthRate` and
   `RelayBandwidthBurst`, these have been renamed to `$relay_bandwidth_rate`
   and `$relay_bandwidth_burst`. If you were using these, please rename your
   variables in your configuration.

 * The variables `$bandwidth_rate` and `$bandwidth_burst` are now used for the
   tor configuration variables `BandwidthRate` and `BandwidthBurst`. If you
   used `$bandwidth_rate` or `$bandwidth_burst` please be aware that these
   values have changed and adjust your configuration as necessary.

 * The `$tor_ensure_version` was converted to a parameter for the tor and
   `tor::daemon` classes.

 * The `$torsocks_ensure_version` was converted to a parameter for the
   `tor::torsocks` class.

 * The options that used to be settable with the `tor::daemon::global_opts`
   define now are parameters for the `tor::daemon class`, and
   `tor::daemon::global_opts` was removed accordingly.


# Dependencies<a name="dependencies"></a>

This module needs:

 * the [concat module](https://github.com/puppetlabs/puppetlabs-concat.git)

# Usage<a name="usage"></a>

## Installing tor<a name="installing-tor"></a>

To install tor, simply include the 'tor' class in your manifests:

    class { 'tor': }

You can specify the `$version` class parameter to get a specific version installed.

However, if you want to make configuration changes to your tor daemon, you will
want to instead include the `tor::daemon` class in your manifests, which will
inherit the `tor` class from above:

    class { '::tor::daemon': }

You have the following class parameters that you can specify:

    data_dir    (default: '/var/lib/tor')
    config_file (default: '/etc/tor/torrc')
    use_bridges (default: 0)
    automap_hosts_on_resolve (default: 0)
    log_rules   (default: ['notice file /var/log/tor/notices.log'])

The `data_dir` will be used for the tor user's `$HOME`, and the tor
`DataDirectory` value.

The `config_file` will be managed and the daemon restarted when it changed.

`use_bridges` and `automap_hosts_on_resolve` are used to set the `UseBridges`
and `AutomapHostsOnResolve` torrc settings.

The `log_rules` can be an array of different Log lines, each will be added to
the config, for example the following will use syslog:

    class { '::tor::daemon':
        log_rules => [ 'notice syslog' ],
    }

If you want to set specific options for the tor class, you may pass them
directly to the tor::daemon in your manifests, e.g.:

    class { '::tor::daemon':
      use_munin                 => true,
      automap_hosts_on_resolve  => 1,
    }

## Configuring SOCKS<a name="configuring-socks"></a>

To configure tor socks support, you can do the following:

    tor::daemon::socks { "listen_locally":
      port     => 0,
      policies => 'your super policy';
    }

## Installing torsocks<a name="installing-torsocks"></a>

To install torsocks, simply include the `torsocks` class in your manifests:

    class { 'tor::torsocks': }

You can specify the `$version` class parameter to get a specific version installed.

# Configuring relays<a name="configuring-relays"></a>

An example relay configuration:

    tor::daemon::relay { "foobar":
      port             => '9001',
      address          => '192.168.0.1',
      bandwidth_rate   => '256',
      bandwidth_burst  => '256',
      contact_info     => "Foo <collective at example dot com>",
      my_family        => '<long family string here>';
    }

You have the following options that can be passed to a relay, with the defaults
shown:
 
    $port                    = 0,
    $portforwarding          = 0,     # PortForwarding 0|1, set for opening ports at the router via UPnP.
                                      # Requires 'tor-fw-helper' binary present.
    $bandwidth_rate          = '',    # KB/s, defaulting to using tor's default: 5120KB/s
    $bandwidth_burst         = '',    # KB/s, defaulting to using tor's default: 10240KB/s
    $relay_bandwidth_rate    = 0,     # KB/s, 0 for no limit.
    $relay_bandwidth_burst   = 0,     # KB/s, 0 for no limit.
    $accounting_max          = 0,     # GB, 0 for no limit.
    $accounting_start        = [],
    $contact_info            = '',
    $my_family               = '', # TODO: autofill with other relays
    $address                 = "tor.${domain}",
    $bridge_relay            = 0,
    $ensure                  = present
    $nickname                = $name

## Configuring the control<a name="configuring-control"></a>

To pass parameters to configure the `ControlPort` and the
`HashedControlPassword`, you would do something like this:

    tor::daemon::control { "foo-control": 
      port                    => '80',
      hashed_control_password => '<somehash>',
      ensure                  => present;
    }

Note: you must pass a hashed password to the control port, if you are going to
use it.

## Configuring onion services<a name="configuring-onion-services"></a>

To configure a tor onion service you can do something like the following:

    tor::daemon::onion_service { "onion_ssh":
      ports => 22;
    }

The `HiddenServiceDir` is set to the `${data_dir}/${name}`, but you can override
it with the parameter `datadir`.

If you wish to enable v3-style onion services to correspond with the v2-style
onion services (the same configuration will be applied to both), you can pass
the parameter `v3 => true`. The default is `false`.

If you wish to enable single-hop onion addresses, you can enable them by
passing `single_hop => true`. The default is `false`.

Onion services used to be called hidden services, so an old interface
`tor::daemon::hidden_service` is still available, with the feature
set of that time.

## Configuring directories<a name="configuring-directories"></a>

An example directory configuration:

    tor::daemon::directory { 'ssh_directory':
      port             => '80',
      port_front_page  => '/etc/tor/tor.html';
    }
  
## Configuring exit policies<a name="configuring-exit-policies"></a>

To configure exit policies, you can do the following:
 
    tor::daemon::exit_policy { "ssh_exit_policy":
      accept => "192.168.0.1:22",
      reject => "*:*";
    }

## Configuring transport plugins<a name="configuring-transport-plugins"></a>

To configure transport plugins, you can do the following:

    tor::daemon::transport_plugins { "obfs4":
      ext_port                => '80',
      servertransport_plugin  => 'obfs4 exec /usr/bin/obfs4proxy',
    }

If you wish to use `obfs4proxy`, you will also need to install the required
Debian package, as the puppet module will not do it for you.

Other options for transport plugins are also available but not defined by
default:

    $servertransport_listenaddr  #Set a different address for the transport plugin mechanism
    $servertransport_options     #Pass a k=v parameters to the transport proxy

# Functions<a name="functions"></a>

This module comes with 2 functions specific to tor support. They require the base32 gem to be installed on the master or wherever they are executed.

## onion_address

This function takes a 1024bit RSA private key as an argument and returns the onion address for an onion service for that key.

## generate_onion_key

This function takes a path (on the puppetmaster!) and an identifier for a key and returns an array containing the matching onion address and the private key. The private key either exists under the supplied `path/key_identifier` or is being generated on the fly and stored under that path for the next execution.

# Munin<a name="munin"></a>

If you are using `munin`, and have the puppet munin module installed, you can
set the `use_munin` parameter to `true` when defining the `tor::daemon` class
to have graphs setup for you.
