# Install the NewRelic Infrastructure Agent
This role installs the NewRelic Infrastructure Agent only.  This role is for monitoring of CPU, Disk Space, RAM, etc.

#### Required Parameters
* newrelic_license_key - Your license key as provided by NewRelic.  This should be encrypted in `/vars/newrelic_license.yml`

#### Sample Execution
```
roles:
    - { role: newrelic_infrastructure, newrelic_license_key: 123123123123123 }
 ```
