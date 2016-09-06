# travisperkins-ansible

Ansible Playbooks for TravisPerkins

The playbooks are designed to manage the autoscaling environment for the OVC
application for TravisPerkins

These playbooks are available to run from ansible tower.

## Run Playbooks from the command line

**PREREQUISITES:**

-   The .vault_pass.txt file MUST be accessible from your user account.
-   You almost definitely want to skip importers.

## Building Whole Environments

If you run a playbook in without any tags or  skip-tags then you will get an
entire environment built with the settings default to that playbook.

    ansible-playbook preprod.yml -e "ovc_version=5.4.0 tp_extension_version=5.4.0 s3_bucket='ovc-travisperkins-releases' deploy=true filebeat=true" --vault-password-file ~/.ssh/.vault_pass.txt

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
'fuzz' levels to be compatible even if other parts nearby have changed.

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
