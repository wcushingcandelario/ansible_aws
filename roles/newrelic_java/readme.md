# Install the NewRelic Java Agent
This role installs the NewRelic Java Agent only.  

#### Required Parameters
* newrelic_license_key - Your license key as provided by NewRelic.  This should be encrypted in `/vars/newrelic_license.yml`
* newrelic_version - The version of newrelic being run. (3.35.2)
* jetty_dir - The directory that jetty is installed in. (/opt/jetty)
* s3_bucket - Where to download the newrelic package

#### Tags

* ad_hoc - These tasks are for using the role on machines that are already running
* baking_ami - This task is used when baking an ami

When baking an ami you need to skip the ad_hoc tags with the __--skip-tags__ flag

When running ad-hoc you need to skip the baking_ami tags with the __--skip-tags__ flag

#### Sample Execution
```
roles:
    - { role: newrelic_java, newrelic_license_key: 123123123123123 newrelic_version: 3.35.2 jetty_dir: /opt/jetty s3_bucket: bucket_name }
 ```
```
ansible-playbook playbook.yml -i inventory_file --skip-tags "baking_ami"
```
#### Sample Ad-Hoc Execution
````
ansible-playbook -i hosts newrelic.yml --private-key ~/.ssh/private-key-here.pem --vault-password-file ~/.ssh/.vault_pass_here.txt --extra-vars=" newrelic_version=3.35.2 jetty_dir=/opt/jetty s3_bucket=ovc-userdata-scripts" --skip-tags "baking_ami" -v
````
