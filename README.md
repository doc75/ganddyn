Ganddyn [![Build Status](https://travis-ci.org/doc75/ganddyn.svg?branch=master)](https://travis-ci.org/doc75/ganddyn)
=======

This gem allows to update your GANDI DNS zone with the current external IPv4 of your machine.
It duplicate current zone information in the last inactive version of the zone (or a newly
created one if only one version exist). It updates the IPv4 for the name requested and activate
this version.

## Installation

Add this line to your application's Gemfile:

    gem 'ganddyn'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ganddyn

## Usage

    $ gannddyn hostname.domain.com GANDIAPIKEY /path/to/file/storing/last/ip/updated

**Warning**:
  - This is an early version not fully tested, use it at your own risk.
  - When used on multiple machines for the same domain, it might miss some update in case of concurrent update

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
