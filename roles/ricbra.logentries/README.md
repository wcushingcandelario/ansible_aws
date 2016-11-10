logentries
==========

This role installs and configures the logentries.com agent.

Requirements
------------

Tested on:
- Debian wheezy, jessie
- Ubuntu trusty, precise, wily, vivid
- Centos 6, 7
- Amazon AMIs

Role Variables
--------------

Only thing required by this role is your logentries.com account key. But you may want to specify additional logs to follow.  

An average configuration looks like this (NOTE: `jetty_dir` and `html_root` are set in `defaults`):

```yml
logentries_account_key: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx"
jetty_dir: /opt/jetty
html_root: /var/www
environment_name: TEST_environment_name

```
Where the variables are:
`logentries_account_key` = The Logentries user key
`jetty_dir` = The location of the Jetty root directory
`html_root` = The location of the OVC Dashboard root directory
`environment_name` = The environment name (log set in logentries) to push this systems logs to

The logs followed are configured in `templates/config.j2` since we create AMIs and deploy them out to various environments.  When NOT specifying the environment name, which typically should not be done unless pushing this role to a specific single environment, the default environment name will be applied as `TEST_environment_name`.  This should be replaced in the bootstrapping of new instances via the user data script.

You can also specify the key of an existing logentries log set if needed:
```yml
logentries_set_key: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

Dependencies
------------

None.

Example Playbook
----------------

Small example of how to use this role in a playbook:

    - hosts: servers
      roles:
         - { role: ricbra.logentries, logentries_account_key: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx" }

Testing
-------

In the <code>vagrant</code> folder you can test this role against a variety of Linux distros:

    $ cd vagrant && vagrant up

License
-------

MIT

Author Information
------------------

Richard van den Brand
