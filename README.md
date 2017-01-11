# travisperkins-ansible

Ansible Playbooks for TravisPerkins

The playbooks are designed to manage the autoscaling environment for the OVC
application for TravisPerkins

These playbooks are available to run from RunDeck.

## Files

-   **README.md** This file.

-   **build_env.yml** Deploy an environment including:

    -   **RDS** (immutable, can be run repeatedly without issue)

    -   **Promo Engine** *Bill to explain this*

    -   **Inventory Manager** *Bill to explain this*

    -   **Either:**

        -   Launch a single instance when `clustered_environment` is *False*, or

        -   Set up an autoscaled environment (LC, ASG, ELB) when a `clustered_environment`

-   **build-new-ami.yml** This creates new machine images with the OVC software.

-   **vars/mb.yml**
-   **vars/tp.yml**
-   **vars/demo.yml** For building an AMI to be deployed in our local environments (runs install_devops_demo)
-   **vars/vanilla.yml** Just for building an AMI, no custom work at all.

-   **test.yml** Does nothing, good for testing the dynamic inventory.

## Nomenclature

**Vanilla** This is a term used for AMIs that have not been customised for any customer including no certificates for the demo account. These AMIs can be customised for any customer without traces of any other.

## Additional -e variables added from the commandline

-   **full_build** This will create an AMI from scratch starting with an Amazon Linux AMI and building the entire thing.

-   **ovc_version** The version of OVC software to find on S3

-   **tp_extension_version** The version of the TP extensions to find on S3

## Run Playbooks from the command line

**PREREQUISITES:**

-   The .vault_pass.txt file MUST be accessible from your user account.
-   You almost definitely want to skip importers.

## Including variable data for customer hosted environments.

You must include the customer variables, for example: `-e @vars/tp.yml`

-   **vars/tp.yml** for Travis Perkins

-   **vars/mb.yml** for Molton Brown

-   **vars/demo.yml** for the Demo account deployment

-   **vars/vanilla.yml** for building a completely non-custom AMI (no extensions, certificates, etc.)

## Building Whole Environments

If you run a playbook in without any tags or skip-tags then you will get an
entire environment built with the settings default to that playbook. **This will
take the latest OVC customised AMI.**

    ansible-playbook preprod.yml -e "ovc_version=5.4.0 tp_extension_version=5.4.0 s3_bucket='ovc-travisperkins-releases' deploy=true filebeat=true" --vault-password-file ~/.ssh/.vault_pass.txt

### What the AMI builder (build-new-ami.yml) does

-   **Role: create_rds**
    This builds the utility RDS database.

-   **Role:promo_engine**
    Builds a promo_engine *Bill*

-   **Role:inventory_manager**
    Builds an inventory_manager *Bill*

-   **The rest**
    This builds the AMI, deploys the software, deploys the configuration, then saves an image of the AMI and terminates it.


### What a play runs

-   **Role: create_rds**
    This builds the main database for the environment.

-   **Role: find_ovc_ami**
    This part finds an AMI that has been built previously by this playbook and
    sets the variables up so that it will be used for the Auto Scaling Group.
    **This is an essential part of almost any play**

-   **Role: asg_main**
    This area of the playbook rolls out the Auto Scaling Group. This will take
    either the AMI just created or the latest AMI to be previously created and
    build out **one** Launch Configuration which then gets run by **one** Auto
    Scaling Groups which is accessible through **two** Load Balancer.

### Skip RDS

You may want to skip RDS if it is already installed. All this does is speed things up.

    ansible-playbook preprod.yml -e "ovc_version=5.4.0 tp_extension_version=5.4.0 s3_bucket='ovc-travisperkins-releases' deploy=true filebeat=true" -e @vars/tp.yml --vault-password-file ~/.ssh/.vault_pass.txt  --skip-tags=importers,rds

### Build with a specific image (AMI)

    ansible-playbook preprod.yml -e "image_id=abc12345 ovc_version=5.4.0 tp_extension_version=5.4.0 s3_bucket='ovc-travisperkins-releases' -e @vars/tp.yml deploy=true filebeat=true" --vault-password-file ~/.ssh/.vault_pass.txt  --skip-tags=importers,rds

## Updating Specific Components

The playbooks are designed to be able to build specific components of any
environment without requiring a complete environment build out.

### I want to... (Cheat Sheet)

One line answers to things you might want to do regularly. These are duplicated
explanations below.

#### ...build an AMI

    ansible-playbook build-new-ami.yml -e "ovc_version=5.4.0 s3_bucket='ovc-travisperkins-releases' deploy=true filebeat=true" -e @vars/vanilla.yml --vault-password-file ~/.ssh/.vault_pass.txt  --skip-tags=importers

#### ...customise an AMI

    ansible-playbook build-new-ami.yml -e @vars/tp.yml -e "ovc_version=5.4.0 tp_extension_version=5.4.0 s3_bucket='ovc-travisperkins-releases' deploy=true filebeat=true" --vault-password-file ~/.ssh/.vault_pass.txt  --skip-tags=importers

#### ...build and customise an AMI from scratch

    ansible-playbook build-new-ami.yml -e @vars/tp.yml -e "ovc_version=5.4.0 tp_extension_version=5.4.0 s3_bucket='ovc-travisperkins-releases' deploy=true filebeat=true full_build=true" --vault-password-file ~/.ssh/.vault_pass.txt  --skip-tags=importers

#### ...customise an AMI and test it

    ansible-playbook build-new-ami.yml -e @vars/tp.yml -e "ovc_version=5.4.0 tp_extension_version=5.4.0 s3_bucket='ovc-travisperkins-releases' deploy=true filebeat=true" --vault-password-file ~/.ssh/.vault_pass.txt  --skip-tags=importers,terminate_ami

### ...deploy an AMI

    ansible-playbook build_env.yml -e @vars/tp.yml -e @vars/tp/preprod.yml -e "ovc_version=5.4.0 tp_extension_version=5.4.0 s3_bucket='ovc-travisperkins-releases' deploy=true filebeat=true" --vault-password-file ~/.ssh/.vault_pass.txt --skip-tags=importers --tags=asg

### Building RDS

This command will install the production database RDS. Notably:

-   If the databases already exist it will do **nothing** and **will not**
    install a new database but simply continue on.

-   Disabling these tags can speed up the play but not by much.

-   This must be run during the rollout of a new environment


    ansible-playbook build_env.yml -e @vars/tp.yml -e @vars/tp/preprod.yml --vault-password-file ~/.ssh/.vault_pass.txt --tags=rds

### Building a new AMI

This playbook will build a new AMI and terminate it. This is **relatively safe**
to run without disrupting the network as long as you **only** bake the AMI and
do not deploy it.

#### Build a vanilla AMI without any customer data
    ansible-playbook build-new-ami.yml -e "ovc_version=5.4.0' deploy=true filebeat=true" -e @vars/vanilla.yml --vault-password-file ~/.ssh/.vault_pass.txt  --skip-tags=importers

#### Add customer data to a vanilla AMI and save it for deployment
    ansible-playbook build-new-ami.yml -e "ovc_version=5.4.0' deploy=true filebeat=true" -e @vars/tp.yml --vault-password-file ~/.ssh/.vault_pass.txt  --skip-tags=importers

#### Build a customer AMI from scratch skipping the vanilla stage
    ansible-playbook build-new-ami.yml -e "ovc_version=5.4.0' deploy=true filebeat=true full_build=true" -e @vars/tp.yml --vault-password-file ~/.ssh/.vault_pass.txt  --skip-tags=importers

#### Build a customer AMI but don't terminate after saving it
This is usually used just for testing. If you want to build an AMI but **not** terminate it so you can evaluate it before deploying then you can skip the termination of the AMI.

    ansible-playbook build-new-ami.yml -e "ovc_version=5.4.0 tp_extension_version=5.4.0 s3_bucket='ovc-travisperkins-releases' deploy=true filebeat=true" -e @vars/tp.yml --vault-password-file ~/.ssh/.vault_pass.txt --skip-tags=importers,terminate_ami

### Deploying a new AMI

Once the AMI has been created it can be deployed into the Auto Scaling Group
using the playbook below. After running this playbook **AMI will be live** in
the environment you have deployed it in. This is limited to the `asg` tag which
just builds the Auto Scaling Group.

    ansible-playbook build_env.yml  -e @vars/tp.yml  -e @vars/tp/preprod.yml -e "ovc_version=5.4.0 deploy=true filebeat=true"--vault-password-file ~/.ssh/.vault_pass.txt  --skip-tags=importers,rds,promo_engine,inventory_manager

## AMI flow - non-production to Production

This is an example of a flow where you build an AMI, test it, and then
progressively roll it out to environments. When we start using this process for
UAT1/UAT2 we can start to create AMI's there and push them through UAT# ->
PreProd -> Production to ensure better testing.

**Firstly build the AMI without terminating:**

    ansible-playbook build-new-ami.yml -e "ovc_version=5.4.0 tp_extension_version=5.4.0 s3_bucket='ovc-travisperkins-releases' deploy=true filebeat=true" -e @vars/tp.yml --vault-password-file ~/.ssh/.vault_pass.txt --skip-tags=importers,terminate_ami

Once this is done you can SSH into the the environment and confirm that
everything has been deployed correctly and is ready to be rolled out into
environments.

**Deploy the AMI into UAT1 (or UAT2):**

    ansible-playbook uat1.yml -e "ovc_version=5.4.0 tp_extension_version=5.4.0 s3_bucket='ovc-travisperkins-releases' deploy=true filebeat=true" -e @vars/tp.yml --vault-password-file ~/.ssh/.vault_pass.txt --skip-tags=importers,mongo

The AMI is now rolled out into UAT1/UAT2 and can be tested to confirm it is
functional. This means specifically that the version of the AMI will work for
a non-clustered environment.

**Deploy the AMI into PreProd:**

    ansible-playbook preprod.yml -e "ovc_version=5.4.0 tp_extension_version=5.4.0 s3_bucket='ovc-travisperkins-releases' deploy=true filebeat=true" -e @vars/tp.yml --vault-password-file ~/.ssh/.vault_pass.txt --skip-tags=importers,mongo

The AMI is now rolled out into PreProd and can be tested to confirm it is
functional. At this point we can roll it out into production knowing it has
worked for PreProd.

**Deploy the AMI into Production:**

    ansible-playbook prod.yml -e "ovc_version=5.4.0 tp_extension_version=5.4.0 s3_bucket='ovc-travisperkins-releases' deploy=true filebeat=true" -e @vars/tp.yml --vault-password-file ~/.ssh/.vault_pass.txt --skip-tags=importers,mongo

Deployment complete!

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

## DNS architecture

We specifically redirect the wickes-tills.co.uk and travisperkins.com DNS
queries to the TP DNS servers. We do this with DNS servers built from an AMI.
If we ever have to produce a new one we simply create new instances of the AMI
and add those IP's to the DHCP config.

DNSMasq snippet:

    server=/wickes-tills.co.uk/172.31.101.101
    server=/wickes-tills.co.uk/172.31.103.112
    server=/wickes-tills.co.uk/172.31.101.103
    server=/wickes-tills.co.uk/172.31.104.102
    server=/travisperkins.com/172.31.101.101
    server=/travisperkins.com/172.31.103.112
    server=/travisperkins.com/172.31.101.103
    server=/travisperkins.com/172.31.104.102
    server=10.33.232.2
