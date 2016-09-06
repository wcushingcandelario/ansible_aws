# travisperkins-ansible

Ansible Playbooks for TravisPerkins

The playbooks are designed to manage the autoscaling environment for the OVC
application for TravisPerkins

These playbooks are available to run from ansible tower.

## Files

-   **README.md** This file.

-   **ami-baker.yml** This builds the AMI, deploys the software, deploys the
    configuration, then saves an image of the AMI and terminates it.

-   **ami-baker_test.yml** Legacy file, to be deleted.

-   **asg_main.yml** This file builds the Auto Scaling Group, Launch
    Configuration, and two Elastic Load Balancers.

-   **aws-create-ovc-from-ami.yml** I'm not aware of what this is (or what it
    is used for), if you do please add the details here.

-   **create-asg-elb.yml** Legacy file, to be deleted.

-   **create-auto.yml** This creates the Launch Config and Auto Scaling Group.

-   **create-elb-dash.yml** This creates the ELB for the Dashboard.

-   **create-elb-pos.yml** This creates the ELB for the POS.

-   **datadog.yml** Legacy file, to be deleted.

-   **mongo-cluster.yml** This builds and deploys the mongo cluster. It will
    deploy a new cluster each time it is run, it does not check for the
    existence of a cluster before running.

-   **preprod.yml** The playbook for the PreProd environment

-   **preprod_ami.yml** Legacy file, to be deleted.

-   **prod.yml** The playbook for the Prod environment.

-   **rds-create.yml** Legacy file, to be deleted.

-   **test-nginx_proxy.yml** Legacy file, to be deleted.

-   **test.yml** Does nothing, good for testing the dynamic inventory.

-   **update-asg.yml** Legacy file, to be deleted.

## Run Playbooks from the command line

**PREREQUISITES:**

-   The .vault_pass.txt file MUST be accessible from your user account.
-   You almost definitely want to skip importers.

## Building Whole Environments

If you run a playbook in without any tags or  skip-tags then you will get an
entire environment built with the settings default to that playbook.

    ansible-playbook preprod.yml -e "ovc_version=5.4.0 tp_extension_version=5.4.0 s3_bucket='ovc-travisperkins-releases' deploy=true filebeat=true" --vault-password-file ~/.ssh/.vault_pass.txt

### What a play runs

-   **Role: create_rds**
    This builds the utility RDS database.

-   **Role: create_rds**
    This builds the main database for the environment.

-   **File: mongo-cluster.yml**
    This builds and deploys the mongo cluster. It will deploy a new cluster
    each time it is run, it does not check for the existence of a cluster before
    running.

-   **File: ami-baker.yml**
    This builds the AMI, deploys the software, deploys the configuration, then
    saves an image of the AMI and terminates it.

-   **Role: findovcami**
    This part finds an AMI that has been built previously by this playbook and
    sets the variables up so that it will be used for the Auto Scaling Group.

-   **File: asg_main.yml**
    This area of the playbook rolls out the Auto Scaling Group. This will take
    either the AMI just created or the latest AMI to be previously created and
    build out **one** Launch Configuration which then gets run by **one** Auto
    Scaling Groups which is accessible through **two** Load Balancer.

### Skip Mongo

You may want to skip Mongo if it is already installed.

    ansible-playbook preprod.yml -e "ovc_version=5.4.0 tp_extension_version=5.4.0 s3_bucket='ovc-travisperkins-releases' deploy=true filebeat=true" --vault-password-file ~/.ssh/.vault_pass.txt  --skip-tags=importers,mongo

### Skip RDS

You may want to skip Mongo if it is already installed.

    ansible-playbook preprod.yml -e "ovc_version=5.4.0 tp_extension_version=5.4.0 s3_bucket='ovc-travisperkins-releases' deploy=true filebeat=true" --vault-password-file ~/.ssh/.vault_pass.txt  --skip-tags=importers,rds,rds_util

## Updating Specific Components

The playbooks are designed to be able to build specific components of any
environment without requiring a complete environment build out.

### Building RDS

This command will install the production database RDS. Notably:

-   If the databases already exist it will do **nothing** and **will not**
    install a new database but simply continue on.

-   Disabling these tags can speed up the play but not by much.

-   This must be run during the rollout


    ansible-playbook prod.yml -e "ovc_version=5.4.0 tp_extension_version=5.4.0 s3_bucket='ovc-travisperkins-releases' deploy=true filebeat=true" --vault-password-file ~/.ssh/.vault_pass.txt  --skip-tags=importers --tags=rds,rds_util

### Building MongoDB

This is the playbook part for the rolls out **three** Mongo database servers in
a cluster and sets the DNS for them.

If you do not skip this then Mongo will redeploy **each and every time** you
run the playbook. You will get a new MongoDB cluster each time you run this
playbook, it does not skip if there are servers already.

    ansible-playbook prod.yml -e "ovc_version=5.4.0 tp_extension_version=5.4.0 s3_bucket='ovc-travisperkins-releases' deploy=true filebeat=true" --vault-password-file ~/.ssh/.vault_pass.txt  --skip-tags=importers --tags=mongo

### Building a new AMI

This playbook will build a new AMI and terminate it. This is **relatively safe**
to run without disrupting the network as long as you **only** bake the AMI and
do not deploy it.

    ansible-playbook prod.yml -e "ovc_version=5.4.0 tp_extension_version=5.4.0 s3_bucket='ovc-travisperkins-releases' deploy=true filebeat=true" --vault-password-file ~/.ssh/.vault_pass.txt  --skip-tags=importers --tags=bake_ami

If you want to build an AMI but **not** terminate it so you can evaluate it
before deploying then you can skip the termination of the AMI.

    ansible-playbook prod.yml -e "ovc_version=5.4.0 tp_extension_version=5.4.0 s3_bucket='ovc-travisperkins-releases' deploy=true filebeat=true" --vault-password-file ~/.ssh/.vault_pass.txt --tags=bake_ami  --skip-tags=importers,terminate_ami

### Deploying a new AMI

Once the AMI has been created it can be deployed into the Auto Scaling Group
using the playbook below. After running this playbook **AMI will be live** in
the environment you have deployed it in.

    ansible-playbook prod.yml -e "ovc_version=5.4.0 tp_extension_version=5.4.0 s3_bucket='ovc-travisperkins-releases' deploy=true filebeat=true" --vault-password-file ~/.ssh/.vault_pass.txt  --skip-tags=importers --tags=asg

## AMI flow - Build and deploy to PreProd in one play

This is a simple play which will create a new AMI and deploy it to the ASG

    ansible-playbook preprod.yml -e "ovc_version=5.4.0 tp_extension_version=5.4.0 s3_bucket='ovc-travisperkins-releases' deploy=true filebeat=true" --vault-password-file ~/.ssh/.vault_pass.txt --skip-tags=importers --tags=bake_ami,asg

## AMI flow - Build and deploy to PreProd in one play w/Mongo

This is a simple play which will create a new AMI and deploy it to the ASG

    ansible-playbook preprod.yml -e "ovc_version=5.4.0 tp_extension_version=5.4.0 s3_bucket='ovc-travisperkins-releases' deploy=true filebeat=true" --vault-password-file ~/.ssh/.vault_pass.txt  --skip-tags=importers --tags=mongo,bake_ami,asg

## AMI flow - non-production to Production

This is an example of a flow where you build an AMI, test it, and then
progressively roll it out to environments. When we start using this process for
UAT1/UAT2 we can start to create AMI's there and push them through UAT# ->
PreProd -> Production to ensure better testing.

**Firstly build the AMI without terminating:**

    ansible-playbook preprod.yml -e "ovc_version=5.4.0 tp_extension_version=5.4.0 s3_bucket='ovc-travisperkins-releases' deploy=true filebeat=true" --vault-password-file ~/.ssh/.vault_pass.txt --tags=bake_ami  --skip-tags=importers,terminate_ami

Once this is done you can SSH into the the environment and confirm that
everything has been deployed correctly and is ready to be rolled out into
environments.

**Deploy the AMI into Pre-Prod:**

    ansible-playbook preprod.yml -e "ovc_version=5.4.0 tp_extension_version=5.4.0 s3_bucket='ovc-travisperkins-releases' deploy=true filebeat=true" --vault-password-file ~/.ssh/.vault_pass.txt --skip-tags=importers --tags=asg

The AMI is now rolled out into PreProd and can be tested to confirm it is
functional. At this point we can roll it out into production knowing it has
worked for PreProd.

**Deploy the AMI into Production:**

    ansible-playbook prod.yml -e "ovc_version=5.4.0 tp_extension_version=5.4.0 s3_bucket='ovc-travisperkins-releases' deploy=true filebeat=true" --vault-password-file ~/.ssh/.vault_pass.txt --skip-tags=importers --tags=asg

## Maintenance

### Patch files for web.xml

**Why patch files?** Simple sed would not always work in this situation so we're
guaranteeing a context to the patch. Patches can also be run with a variety of
'fuzz' levels to be compatible even if other parts nearby have changed. These
are found in:

    roles/oneview/files/cometd/

Importantly patch files **do not** modify the whole file like a template or copy
and so don't risk removing other updates that have been made to the same file.
These patches are run in the user_data.sh script which is used within the Launch
Configuration. **All patches** for **all environments** are included in **every
AMI** so it is important to rebuild the AMI if you change a patch.

-   Copy the latest version of the web.xml file into oroginal.xml, preprod.xml
    and prod.xml.

-   Attempt to patch the files using the existing patches, this way you can
    increase how liberal patch is if needed. Otherwise manually patch them.


    patch ./preprod.xml ./web.xml.patch.preprod
    patch ./prod.xml ./web.xml.patch.prod

-   Generate new strict patches from the diff's you can create now you have an
    original and a destination.


    diff -Naur original.xml prod.xml > ./web.xml.patch.prod
    diff -Naur original.xml preprod.xml > ./web.xml.patch.preprod

-   Remember to commit the .xml files and the patch files into git so anyone
    else can reproduce your work.

### Non-patch environment files

These are not patch files or substitution processes, they require detailed
attention with each release. Unfortunately we cannot presume the latest changes
to any of these files until they are made and so no 'one size fits all' system
can be implemented without risk that the files change with new fields and that
these new fields also require changing before deployment.

#### File names

-   context.xml
-   database.php
-   setting_var.php
-   tools.properties
-   unifiedConfig.properties

#### Process to update

With each new release in UAT we should take the files generated there and update
the files held within Ansible to contain the same fields. One can compare the
two files as so (or with any other editor):

    meld context.xml.uat roles/oneview/env_files/context.xml.prod

The two files should not be identical but the prod/preprod files should include
**all** of the fields that the UAT ones include.

#### Important note about context.xml

This file is a template but is added by file_glob. This means that **the
context.xml template lives in files/** which seems pretty odd. Please, **do not
move it to teplates/, it will not work**. Really, we've tested it by mistake.

## NGINX architecture

**Note:** There are better ways to do this. Unfortunately the combination of
which version of NGINX is used and the dashboard not supporting SSL means that
this is the only way we have found so far.

### /ovcdashboard

This is the more complex part of the NGINX configuration. To display the
dashboard we have to proxy it **twice**. There are several reasons for this.

-   We must replace all links changing http:// to https:// using sub_filter to
    'enable' https on the dashboard. This is probably because the
    X-Forwarded-Proto and similar variables are not read correctly by the
    dashboard. Developers are looking into this.

-   When Any other proxy_set_header is set `Accept-Encoding "";` does not get
    sent or processed correctly. When this is the case the sub_filter will not
    work because the data is compressed.

-   When `Accept-Encoding "";` is set and no other heading the application at
    the other end of the proxy believes that the fetching host (the client) is
    the proxy (localhost, the server) and that the remote IP it accessed
    (X-Real-IP) is in fact localhost. All links are then written to
    `https://localhost:9080` which is the address which we proxy to (http not
    https but we're substituting, right). This renders the app broken and is
    frankly annoying.

-   The version of NGINX we have only uses **one** sub_filter and so we cannot
    do search and replace twice in the same block.

-   To do two substitutions (http to https, localhost to $host) we have to do
    two proxy passes. One for each substitution.

So, the architecture looks like this:

    Client (browser) -> /ovcdashboard (first proxy) -> /ovcdashboardproxy (second proxy) -> localhost:9080 (Apache)

This does mean that every request goes through the proxy **twice** which is a
bit messy.

![I'm sorry. I'm so, so sorry](https://i2.wp.com/s3-ak.buzzfeed.com/static/2014-05/tmp/webdr05/12/19/anigif_eaa6a580d8aece464ad6ec5fd8670b68-0.gif)

### Jetty (/cometd and /)

This does conform to normal sane structure but does require the HTTP version to
be set as well as the Connection and Upgrade fields for CometD. Also, under /
it is important to remember that the proxy_set_header fields populate data about
where the connection originally came from (client, browser) not where it was
proxied (server, localhost).

    location /cometd {
        proxy_set_header Accept-Encoding "";
        proxy_set_header HOST $host;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_http_version 1.1;
        proxy_pass http://localhost:8080;
    }


    location / {
        proxy_set_header Accept-Encoding "";
        proxy_set_header HOST $host;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_pass http://localhost:8080;
    }

## How machines become environment specific

Each AMI that is created is completely environment non-specific. Without making
any changes the AMI - if booted as a new machine - will not connect to an
environment and would not function as a usable OVC environment.

Within the AMi several configuration files are pre-populated, into the
directories which hold the running configuration files.

    /opt/jetty/webapps/context.xml
    /opt/jetty/webapps/context.xml.prod
    /opt/jetty/webapps/context.xml.preprod

When the Launch Configuration is created a set of User Data is added in to it
and when each machine is launched it runs that User Data. The User Data is a
shell script which in our case mostly moves some files around and can be found
in `scripts/user_data.sh`. Once the User Data script has been run the machine
will function within the environment.
