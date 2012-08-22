# Clockwork Raven [![Build Status](https://secure.travis-ci.org/twitter/clockworkraven.png)](http://travis-ci.org/twitter/clockworkraven) [![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/twitter/clockworkraven)

## Human-Powered Data Analysis

Clockwork Raven is a web application that allows users to easily submit data
to Mechanical Turk for manual review, and then analyze that data. Clockwork Raven is
actively used at Twitter to gather tens of thousands of judgments from Mechanical Turk
users weekly.

### What it is good for

Clockwork Raven is designed for individuals, or organizations that share a
single Mechanical Turk account. It allows users to authenticate with LDAP or
with accounts created through Clockwork Raven. Users can then upload data,
design forms to send to Mechanical Turk through a simple, drag-and-drop
interface, submit these forms to Mechanical Turk, and review the results.

Administrators can separate users into "privileged" and "unprivileged" sets
manually or based on LDAP groups. Unprivileged uses are not allowed to spend
money, but can submit evaluations to the Mechanical Turk sandbox to test out
the system, and can design evaluations and ask a privileged user to submit
the evaluation on his or her behalf.

To help control the quality of responses, Clockwork Raven allows you to restrict
the tasks you send to Mechanical Turk to only those users who Mechanical Turk
has deemed "Categorization Masters", or to only those users who you have marked
as Trusted in Clockwork Raven.

### What it is not good for

Clockwork Raven is designed for situations where **everyone who has access to
the system is relatively trusted.** Because the form designer allows users to
use arbitrary HTML, anyone with access to the system could execute an
[XSS](http://en.wikipedia.org/wiki/Cross-site_scripting) attack and compromise
the system.

However, Clockwork Raven will not give access to users unless they are part of
white-listed LDAP groups or have been explicitly granted access. Users cannot
create accounts for themselves.

## Setup

1. Check out the code from https://github.com/twitter/clockworkraven
2. Requirements:
    1. Make sure the machine that you're using has Ruby 1.9.3
       installed. The easiest way to install and manage Ruby is with
       [RVM](https://rvm.io/).
    2. You'll need the RubyGem "bundler" installed, and then just run `bundle
       install` from the Clockwork Raven directory to install all of the
       libraries needed by Clockwork Raven.
    3. Clockwork Raven uses [Resque](https://github.com/defunkt/resque/) to run
       tasks in the background. Resque requires a Redis server -- see
       [Resque's instructions for installing Redis](https://github.com/defunkt/resque/#installing-redis).
       By default Clockwork Raven assumes your Redis server is running on
       `localhost:6379`. If this isn't the case, edit `config/resque.yml`.
    4. In a production environment (e.g. any environment where Clockwork
       Raven will be accessible to users), it should be run over SSL to protect
       users' credentials when they log in. If you don't use SSL, these
       credentials will be sent over the network in the clear!
3. Configure:
    1. Generate a secret key. Copy `config/secret.example.yml` to
       `config/secret.yml`. Then, run `rake secret` and copy the output to
       `config/secret.yml`.
    2. Copy `config/database.example.yml` to `config/database.yml` and modify it
       to point to your MySQL database. Currently, Clockwork Raven only supports
       MySQL.
    3. Copy `config/mturk.example.yml` to `config/mturk.yml`. Follow the
       instructions in that file to connect Clockwork Raven to your Mechanical
       Turk account.
    4. Configure authentication:

       **LDAP Authentication**

       LDAP authentication is the recommended way to manage account in Clockwork
       Raven. If your LDAP server supports SSL/TLS, copy
       `config/auth.example_ldap_encrypted.yml` to `config/auth.yml`. If your LDAP
       server does not, copy `config/auth.example_ldap_unencrypted.yml`
       to `config/auth.yml`. Follow the instructions in that file to connect
       Clockwork Raven to your LDAP server and grant access to specific LDAP
       groups and users.

       **Password Authentication**

       If you can't use an LDAP server, you can configure Clockwork Raven to use
       "password authentication," which will allow you to manually create
       accounts. Copy `config/auth.example_password.yml` to `config/auth.yml`. Then,
       you can create accounts by running "rake users:add" and change passwords
       with `rake users:change_password`. Note that you will need to set up your
       database (explained below) before using these rake tasks.
4. Set up the database. If the databases you configured Clockwork Raven to use in
   `config/database.yml` do not exist, run `rake db:create` to create them.
   Then, run `rake db:structure:load` to load the database structure into your
   database.
5. Start up the background workers. Just
   run `rake raven:resque` to start up 4 background workers. You can start
   up more background workers by passing an argument to the rake task:
   `rake raven:resque[16]` will start up 16 background workers.
6. Run the server. To run the server, run `rails server`.

## Documentation

Documentation is available on the
[wiki](https://github.com/twitter/clockworkraven/wiki).

## Contact

Follow [@clockworkraven](https://twitter.com/clockworkraven) for updates and
notifications. Submit bug report and feature requests to the
[issue tracker](https://github.com/twitter/clockworkraven/issues).

Join the mailing list,
[twitter-clockworkraven@googlegroups.com](mailto:twitter-clockworkraven@googlegroups.com),
on
[Google Groups](http://groups.google.com/group/twitter-clockworkraven) to
ask questions and discuss development.

## Roadmap

We would love any help adding ideas or implementing them!

* JSON/REST API.
* Provide the option to have multiple Mechanical Turk users complete each task.
* Provide in-depth analytics about workers and automate the process of choosing
  trusted workers.

## Contributing

To contribute to Clockwork Raven, fork the repo, make your changes, and
submit a pull request. All pull requests should be against `*-wip` branches.
Nothing gets committed/merged directly to master. To merge your pull request,
you'll need to include appropriate documentation and tests. Get in touch if you
have any questions about what you need to do to get your contributions accepted.

## Authors

* Ben Weissmann, [@benweissmann](https://twitter.com/benweissmann)
* Edwin Chen, [@echen](https://twitter.com/echen)
* Dave Buchfuhrer, [@daveFNbuck](https://twitter.com/daveFNbuck)

## Versioning

The current version is in the VERSION file and accessible in the code as
ClockworkRaven::VERSION. Releases will be tagged with their release number in
Git.

Clockwork Raven uses [semantic versioning](http://semver.org). Basically,
this means that versions will be of the form X.Y.Z, where X is the major version
(incremented when backwards-incompatible changes are introduced), Y is the minor
version (incremented when backwards-compatible features are introduced), and X
is the patch number (incremented when backwards-compatible bug fixes are
introduced). Note, however, that these are only hard rules once Clockwork Raven
reaches 1.x. Until then, we will do our best to adhere to these policies
(particularly with regards to not introducing backwards-incompatible changes in
patch releases), but we may make backwards-incompatible changes while only
incrementing the minor version number.

## License

Copyright 2012 Twitter, Inc.

Licensed under the Apache License, Version 2.0: http://www.apache.org/licenses/LICENSE-2.0
