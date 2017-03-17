# The git repository currently known as travisperkins-ansible

Ansible Playbooks set to replace the ansible-playbooks repo.

Some of these playbooks are run automatically and manually to create AWS machine
images for use within auto-scaling groups. Other playbooks are run manually
through RunDeck to produce auto-scaling environments.

These playbooks are available to run from RunDeck.

### Nomenclature

**Vanilla** This is a term used for AMIs that have not been customised for any
customer including no certificates for the demo account. These AMIs can be
customised for any customer without traces of any other.

**AMI** An image of a server which is used to boot identical servers, this is a
static image which produces an immutable environment which **cannot** be changed
on the fly and **must** be rebuilt with a new AMI each time

## User Guide

This is the general use guide for the **Development Team** and the **DevOps
Team** when building AMIs and maintainng existing environments.

### Overview of Steps

  1. *Demo Account:* CircleCI builds a new *Vanilla* Mobile POS Solution (*No customer data, no
    custom jars*) AMI.

  2. *Demo Account:* CircleCI builds a new *customer* AMI.

  3. *Customer Account:* Run the `Release AMI` play on RunDeck.

  4. *Customer Account:* Run the `Build AMI Environment` play on RunDeck.

### Building an AMI

Building AMIs should always be done through CircleCI or RunDeck. By preference
the AMIs should have come from CircleCI or our build system needs to be updated.
However there is the provision to build specific (non standard or pre-CircleCI)
AMIs manually through RunDeck.

Building AMIs from the commandline should not be needed any more and is not
advised. The RunDeck and CircleCI definitions will by product of code evolution
be updated far more regularly and completely than this document.

#### Vanilla Mobile POS Solution Images (*No customer jars or data*)

By default these are built on commit to `develop`, `master`, `hotfix-*`, and
`release-*` using CircleCI. The line which controls this is 'build-new-ami.sh'
and it is important that this builds as regularly as possible in case some
change is introduced which would prevent the AMI from successfully building but
would not be otherwise noticed until release time.

So, automatically, from each commit to the above branches a new AMI will be
built with the correct tags showing the branch and git SHA which it was created
from. This process also tags anything built from the master branch as a release
AMI. The 'release' tag for the AMI is important because it supplies a branch
independent way for an environment builder to pick the latest AMI which is ready
for prime-time.

If an AMI build did not happen for any reason, or if you need to build an AMI
from **before** the CircleCI automatic AMI building was implemented this is
available through the OVC Demo RunDeck on
<http://rundeck.ovcdemo.com:4440/project/AMI_environment_management/jobs/AMI_Builds>.
To build an AMI one would chose `Vanilla CIrcleCI AMI Builder`; there you fill
out the OVC Version with the version that you need (no need to add `-SNAPSHOT`
for develop, this will be done automatically by RunDeck), the branch to build
from and the git SHA of the commit you want. This information is used to access
the S3 bucket `ovc-release-provisioner` and the prefix
`ovc-server-rolling-builds` to find the OVC install file required to build the
AMI. **Please remember, normally you will never need to do this, it will be done
for you on commit**

If for some reason you need to build an AMI manually from scratch without the
help of RunDeck the following code snippet is what is used by RunDeck to build
the CircleCI-like AMIs. You will need to declare or replace the variables:
-   **OVC_VERSION** - The version of the OVC Mobile POS Solution which you wish
    to build from.
-   **RD_OPTION_GIT_BRANCH** - The git branch which you want to build off of for
    example:
    *   `hotfix-5.19.4`
    *   `release-5.1.0`
    *   `master`
    *   `hotfix-5.13.1`
    *   `develop`
    *   `release-5.14.0`
    *   `DEVOPS-999-FIx-my-feature`
-   **RD_OPTION_GIT_SHA** - The SHA of the commit you want to build from. This
    is used to find the install ZIP from the S3 repository.
-   **AMI_RELEASE** - Usually set to `alpha`, this should be set to `release`
    when you build from master (automatically done by RunDeck).
```
ansible-playbook build-new-ami.yml \
  -e @vars/vanilla.yml \
  -e "ovc_version=${OVC_VERSION}" \
  -e "s3_ovc_object=ovc-server-rolling-builds/${RD_OPTION_GIT_BRANCH}/${RD_OPTION_GIT_SHA}" \
  -e "s3_bucket=ovc-release-provisioner" \
  -e "\{'ssl_secret_files': \{'test': 'test'\}\}" \
  -e "ovc_git_sha=${RD_OPTION_GIT_SHA} ovc_circle_branch=${RD_OPTION_GIT_BRANCH} ami_release=${AMI_RELEASE}" \
  --vault-password-file="~/.ssh/.vault_pass.txt" \
  --skip-tags=importers,startjetty,rds_util \
  -vv
```

#### Customer Specific Images (*Includes customer jars and data*)

By default these are built on commit to `develop`, `master`, `hotfix-*`, and
`release-*` using CircleCI. The line which controls this is 'build-new-ami.sh'
and it is important that this builds as regularly as possible in case some
change is introduced which would prevent the AMI from successfully building but
would not be otherwise noticed until release time.

So, automatically, from each commit to the above branches a new AMI will be
built with the correct tags showing the branch and git SHA which it was created
from. This process also tags anything built from the master branch as a release
AMI. The 'release' tag for the AMI is important because it supplies a branch
independent way for an environment builder to pick the latest AMI which is ready
for prime-time.

**At this point there are only on AMI builds for TP**

If an AMI build did not happen for any reason, or if you need to build an AMI
from **before** the CircleCI automatic AMI building was implemented this is
available through the OVC Demo RunDeck on
<http://rundeck.ovcdemo.com:4440/project/AMI_environment_management/jobs/AMI_Builds>.
To build an AMI one would chose `TP CircleCI AMI Builder`; there you fill
out the OVC Version with the version that you need (no need to add `-SNAPSHOT`
for develop, this will be done automatically), the branch to build from and the
git SHA of the commit you want. This information is used to access the S3 bucket
`ovc-release-provisioner` and the prefix `ovc-server-rolling-builds` to find the
OVC install file required to build the AMI. **Please remember, normally you will
never need to do this, it will be done for you on commit**

If for some reason you need to build an AMI manually from scratch without the
help of RunDeck the following code snippet is what is used by RunDeck to build
the CircleCI-like AMIs. You will need to declair or replace the variables:
-   **OVC_VERSION** - The version of the OVC Mobile POS Solution which you wish
    to build from.
-   **RD_OPTION_EXT_VERSION** - The version of the customer extensions you wish
    to install.
-   **RD_OPTION_S3_BUCKET_CUSTOMER** - Almost always `ovc-gradle-repo`
-   **RD_OPTION_S3_FULL_ZIP_PREFIX** - If not set to false this will pre-pend
    the value of this variable to the version information when searching for
    **a full zip file with all the extensions and data in** otherwise it will
    expect to find the jar files and data files in a folder named after the
    version directly in the root of the S3 bucket. Set this value if you expect
    a file like `TPCustomPackage-5.13.0.zip` or use *false* when dealing with
    files like `tpdata.tar.gz`, `TPPopulators-5.4.0.jar` and
    `TPExtensions-5.4.0.jar`.
    *   `false` specifically used to avoid the prefix and expect the version to
        be in the root of the S3 bucket.
    *   `hotfixes/com/oneview/TPCustomPackage/`
    *   `rcs/com/oneview/TPCustomPackage/`
    *   `releases/com/oneview/TPCustomPackage/`
    *   `snapshots/com/oneview/TPCustomPackage/`
-   **RD_OPTION_GIT_BRANCH** - The git branch which you want to build off of for
    example:
    *   `hotfix-5.19.4`
    *   `release-5.1.0`
    *   `master`
    *   `hotfix-5.13.1`
    *   `develop`
    *   `release-5.14.0`
    *   `DEVOPS-999-FIx-my-feature`
-   **RD_OPTION_GIT_SHA** - The SHA of the commit you want to build from. This
    is used to find the install ZIP from the S3 repository.
-   **AMI_RELEASE** - Usually set to `alpha`, this should be set to `release`
    when you build from master (automatically done by RunDeck).

```
ansible-playbook build-new-ami.yml \
  -e @vars/tp.yml \
  -e @vars/tp.yml.encrypted \
  -e "ovc_version=${RD_OPTION_OVC_VERSION} tp_extension_version=${RD_OPTION_EXT_VERSION}" \
  -e "s3_bucket_customer=${RD_OPTION_S3_BUCKET_CUSTOMER}" \
  -e "s3_full_zip_prefix=${RD_OPTION_S3_FULL_ZIP_PREFIX}" \
  -e 'staffDiscount_bucketName=BOB' \
  -e "ovc_git_sha=${RD_OPTION_GIT_SHA1} ovc_circle_branch=${RD_OPTION_GIT_BRANCH} ami_release=${AMI_RELEASE}" \
  -e "find_ami_branch=${RD_OPTION_GIT_BRANCH}" \
  --vault-password-file ~/.ssh/.vault_pass.txt \
  --skip-tags=importers,import_custom_db,startjetty,rds_util \
  -vv
```

### Deploying an AMI

#### Mark an AMI for release in a customer

Once you know which AMI you want to enable in the customer environment go to the
`Release AMI` job in RunDeck on the customer's environment and use the AMI ID to
release it so it will be seen by the `Build AMI Environment` playbook.

#### Deploy the AMI using RunDeck

This is a simple process, all automated by RunDeck. The `Build AMI Environment`
job in RunDeck will build an environment as required. All this requires is the
OVC version.

### AMI flow - Customer non-production to Production

This is an example of a flow where you build an AMI, test it, and then
progressively roll it out to environments. When we start using this process for
UAT1/UAT2 we can start to create AMI's there and push them through UAT# ->
PreProd -> Production to ensure better testing.

### Deploy a mongo AMI

This will build an AMI using MongoDB Cloud Manager.  

**Pre-customer: Build a vanilla AMI and test it**

*Run from: Demo account*

**RunDeck:** Vanilla CircleCI AMI Builder

Now you should have an AMI that can be used in local environments for testing of
the OVC core functionality, in the next step we will make it specific to the
customer.

**Firstly build the AMI:**

*Run from: Demo account*

**RunDeck:** TP CircleCI AMI Builder

Once this is done you can confirm that everything has been deployed correctly
and is ready to be rolled out into environments.

**Enable the AMI (mark as release):**

*Run from: Customer account*

**RunDeck:** Release AMI


**Deploy the AMI into UAT1 (or UAT2):**

*Run from: Customer account*

**RunDeck:** Build AMI Environment

The AMI is now rolled out into UAT1/UAT2 and can be tested to confirm it is
functional. This means specifically that the version of the AMI will work for
a non-clustered environment.

**Deploy the AMI into PreProd:**

*Run from: Customer account*

**RunDeck:** Build AMI Environment

The AMI is now rolled out into PreProd and can be tested to confirm it is
functional. At this point we can roll it out into production knowing it has
worked for PreProd.

**Deploy the AMI into Production:**

*Run from: Customer account*

**RunDeck:** Build AMI Environment

Deployment complete!

## Ad-Hoc Playbooks
The following are a list of plays that can be run ad-hoc against a running Amazon Linux based OneView server with examples.

##### logentries.yml
LogEntries is a tool that offloads logs to https://www.logentries.com.  As a *best practice* (since LogEntries doesn't have environment sorting) include the customer name and environment in the `environment_type` variable.  This variable shows up in the LogEntries UI and makes finding your environment easy.  _*Note:*_ Internal environments with `ovcdemo.com` domains have `OVCDevelopment` as the `CUSTOMER_NAME`.
```
ansible-playbook -i my_hosts logentries.yml -e "environment_name=[CUSTOMER_NAME_GOES_HERE]-ENVIRONMENT_GOES_HERE" --vault-password-file ~/.ssh/.vault_pass.txt
```



## Development Information

You probably don't need to read any further unless you wish to understand
architecture of the AMi building process or some of the DevOps engineered work
that has been done to get to this point.

If you are interested in stories with happy endings you would be better off
reading some other README. In this following developer guide not only is there
no happy ending there is no happy beginning and very few happy things in the
middle. In fact here below you will simply find trouble, DevOps tricks, and some
considerable discomfort.

Here DevOps refers to the group of people who tirelessly work around unexpected
problems to deliver usable servers.

![Lemony Snicket explaining the unfortunate series of DevOps](http://www.indiewire.com/wp-content/uploads/2016/10/lemony-snicket.jpg?w=780)

### Files

-   **README.md** This file.
-   **build_env.yml** Deploy an environment including:
    -   **RDS** (immutable, can be run repeatedly without issue)
    -   **Promo Engine** Optional module. Deploys to Beanstalk.
    -   **Inventory Manager** Optional module. Deploys to Beanstalk.
    -   **Either:**
        -   Launch a single instance when `clustered_environment` is *False*, or
        -   Set up an autoscaled environment (LC, ASG, ELB) when a
            `clustered_environment`
-   **build-new-ami.yml** This creates new machine images with the OVC software.
-   **vars/mb.yml**
-   **vars/tp.yml**
-   **vars/demo.yml** For building an AMI to be deployed in our local
    environments (runs install_devops_demo)
-   **vars/vanilla.yml** Just for building an AMI, no custom work at all.
-   **test.yml** Does nothing, good for testing the dynamic inventory.

### Additional -e variables added from the commandline

-   **ovc_version** The version of OVC software to find on S3
-   **tp_extension_version** The version of the TP extensions to find on S3

### Run Playbooks from the command line

**PREREQUISITES:**

-   The .vault_pass.txt file MUST be accessible from your user account.
-   You almost definitely want to skip importers.

### Including variable data for customer hosted environments.

You must include the customer variables, for example: `-e @vars/tp.yml`

-   **vars/tp.yml** for Travis Perkins
-   **vars/mb.yml** for Molton Brown
-   **vars/demo.yml** for the Demo account deployment
-   **vars/vanilla.yml** for building a completely non-custom AMI (no
    extensions, certificates, etc.)
-   **vars/demo.yml.encrypted** for building mongo instance

You must also include the environment variables, such as `-e @vars/tp/uat1.yml`.

### Building Whole Environments

If you run a playbook in without any tags or skip-tags then you will get an
entire environment built with the settings default to that playbook. **This will
take the latest OVC customised AMI.**

```
ansible-playbook build_env.yml \
  -e @vars/tp.yml \
  -e @vars/tp/preprod.yml \
  -e "ovc_version=5.4.0 deploy=true" \
  --vault-password-file ~/.ssh/.vault_pass.txt
```

### Building Whole Environments with MongoDB

```
ansible-playbook build_env.yml \
  -e @vars/tp.yml \
  -e @vars/tp/preprod.yml \
  -e "ovc_version=5.4.0 deploy=true" \
  -e @vars/demo.yml.encrypted \
  --vault-password-file ~/.ssh/.vault_pass.txt
```

#### What an environment play runs
-   **Role: create_rds**
    This builds the main database for the environment.

-   **Role: promo_engine**
    Builds and/or updates the Promotion Engine in a beanstalk environment.

-   **Role: inventory_manager**
      Builds and/or updates the Promotion Engine in a beanstalk environment.

-   **Role: find_ovc_ami**
    This part finds an AMI that has been built previously by this playbook and
    sets the variables up so that it will be used for the Auto Scaling Group.
    **This is an essential part of almost any play**

-   **Role: launch_ami**
    Like asg_main this is where the play will launch an individual instance if the environment is non-clustered. We set clustering of an environment with the `clustered_environment` variable.

-   **Role: mongodb_cm**
    Builds a mongo instance through MongoDB Cloud Manager


-   **Role: create-elb-pos, create-elb-dash, create-auto**
    This area of the playbook rolls out the Auto Scaling Group. This will take
    either the AMI just created or the latest AMI to be previously created and
    build out **one** Launch Configuration which then gets run by **one** Auto
    Scaling Groups which is accessible through **two** Load Balancer.

#### Skip RDS

You may want to skip RDS if it is already installed. All this does is speed things up.

```
ansible-playbook preprod.yml \
  -e "ovc_version=5.4.0 tp_extension_version=5.4.0 s3_bucket='ovc-travisperkins-releases' deploy=true" \
  -e @vars/tp.yml \
  --vault-password-file ~/.ssh/.vault_pass.txt \
  --skip-tags=importers,rds
```

#### Build with a specific image (AMI)

```
ansible-playbook preprod.yml \
  -e "image_id=abc12345 ovc_version=5.4.0 tp_extension_version=5.4.0 s3_bucket='ovc-travisperkins-releases' \
  -e @vars/tp.yml deploy=true" \
  --vault-password-file ~/.ssh/.vault_pass.txt \
  --skip-tags=importers,rds
```

### Updating Specific Components

The playbooks are designed to be able to build specific components of any
environment without requiring a complete environment build out.

#### Building RDS

This command will install the production database RDS. Notably:

-   If the databases already exist it will do **nothing** and **will not**
    install a new database but simply continue on.

-   Disabling these tags can speed up the play but not by much.

-   This must be run during the rollout of a new environment


```
ansible-playbook build_env.yml \
  -e @vars/tp.yml \
  -e @vars/tp/preprod.yml \
  --vault-password-file ~/.ssh/.vault_pass.txt \
  --tags=rds
```

#### Building a new AMI

This playbook will build a new AMI and terminate it. This is **relatively safe**
to run without disrupting the network as long as you **only** bake the AMI and
do not deploy it.

##### Build a vanilla AMI without any customer data

-   **OVC_VERSION** - The version of the OVC Mobile POS Solution which you wish
    to build from.
-   **RD_OPTION_GIT_BRANCH** - The git branch which you want to build off of for
    example:
    *   hotfix-5.19.4
    *   release-5.1.0
    *   master
    *   hotfix-5.13.1
    *   develop
    *   release-5.14.0
    *   DEVOPS-999-FIx-my-feature
-   **RD_OPTION_GIT_SHA** - The SHA of the commit you want to build from. This
    is used to find the install ZIP from the S3 repository.
-   **AMI_RELEASE** - Usually set to `alpha`, this should be set to `release`
    when you build from master (automatically done by RunDeck).

```
ansible-playbook build-new-ami.yml \
  -e @vars/vanilla.yml \
  -e "ovc_version=${OVC_VERSION}" \
  -e "s3_ovc_object=ovc-server-rolling-builds/${RD_OPTION_GIT_BRANCH}/${RD_OPTION_GIT_SHA}" \
  -e "s3_bucket=ovc-release-provisioner" \
  -e "\{'ssl_secret_files': \{'test': 'test'\}\}" \
  -e "ovc_git_sha=${RD_OPTION_GIT_SHA} ovc_circle_branch=${RD_OPTION_GIT_BRANCH} ami_release=${AMI_RELEASE}" \
  --vault-password-file="~/.ssh/.vault_pass.txt" \
  --skip-tags=importers,startjetty,rds_util \
  -vv
```

##### Add customer data to a vanilla AMI and save it for deployment
-   **OVC_VERSION** - The version of the OVC Mobile POS Solution which you wish
    to build from.
-   **RD_OPTION_EXT_VERSION** - The version of the customer extensions you wish
    to install.
-   **RD_OPTION_S3_BUCKET_CUSTOMER** - Almost always `ovc-gradle-repo`
-   **RD_OPTION_S3_FULL_ZIP_PREFIX** - If not set to false this will pre-pend
    the value of this variable to the version information when searching for
    **a full zip file with all the extensions and data in** otherwise it will
    expect to find the jar files and data files in a folder named after the
    version directly in the root of the S3 bucket. Set this value if you expect
    a file like `TPCustomPackage-5.13.0.zip` or use *false* when dealing with
    files like `tpdata.tar.gz`, `TPPopulators-5.4.0.jar` and
    `TPExtensions-5.4.0.jar`.
    *   `false` specifically used to avoid the prefix and expect the version to
        be in the root of the S3 bucket.
    *   `hotfixes/com/oneview/TPCustomPackage/`
    *   `rcs/com/oneview/TPCustomPackage/`
    *   `releases/com/oneview/TPCustomPackage/`
    *   `snapshots/com/oneview/TPCustomPackage/`
-   **RD_OPTION_GIT_BRANCH** - The git branch which you want to build off of for
    example:
    *   hotfix-5.19.4
    *   release-5.1.0
    *   master
    *   hotfix-5.13.1
    *   develop
    *   release-5.14.0
    *   DEVOPS-999-FIx-my-feature
-   **RD_OPTION_GIT_SHA** - The SHA of the commit you want to build from. This
    is used to find the install ZIP from the S3 repository.
-   **AMI_RELEASE** - Usually set to `alpha`, this should be set to `release`
    when you build from master (automatically done by RunDeck).

```
ansible-playbook build-new-ami.yml \
  -e @vars/tp.yml \
  -e "ovc_version=${RD_OPTION_OVC_VERSION} tp_extension_version=${RD_OPTION_EXT_VERSION}" \
  -e "s3_bucket_customer=${RD_OPTION_S3_BUCKET_CUSTOMER}" \
  -e "s3_full_zip_prefix=${RD_OPTION_S3_FULL_ZIP_PREFIX}" \
  -e 'staffDiscount_bucketName=BOB' \
  -e "ovc_git_sha=${RD_OPTION_GIT_SHA1} ovc_circle_branch=${RD_OPTION_GIT_BRANCH} ami_release=${AMI_RELEASE}" \
  -e "find_ami_branch=${RD_OPTION_GIT_BRANCH}" \
  --vault-password-file ~/.ssh/.vault_pass.txt \
  --skip-tags=importers,import_custom_db,startjetty,rds_util,mongodb_cm \
  -vv
```

##### Build a customer AMI but don't terminate after saving it
This is usually used just for testing. If you want to build an AMI but **not**
terminate it so you can evaluate it before deploying then you can skip the
termination of the AMI. Basically this adds the terminate_ami skip-tags.

```
ansible-playbook build-new-ami.yml \
  -e @vars/tp.yml \
  -e "ovc_version=${RD_OPTION_OVC_VERSION} tp_extension_version=${RD_OPTION_EXT_VERSION}" \
  -e "s3_bucket_customer=${RD_OPTION_S3_BUCKET_CUSTOMER}" \
  -e "s3_full_zip_prefix=${RD_OPTION_S3_FULL_ZIP_PREFIX}" \
  -e 'staffDiscount_bucketName=BOB' \
  -e "ovc_git_sha=${RD_OPTION_GIT_SHA1} ovc_circle_branch=${RD_OPTION_GIT_BRANCH} ami_release=${AMI_RELEASE}" \
  -e "find_ami_branch=${RD_OPTION_GIT_BRANCH}" \
  --vault-password-file ~/.ssh/.vault_pass.txt \
  --skip-tags=importers,import_custom_db,startjetty,rds_util,terminate_ami,mongodb_cm \
  -vv
```

#### Deploying a new AMI

Once the AMI has been created it can be deployed into the Auto Scaling Group
using the playbook below. After running this playbook **AMI will be live** in
the environment you have deployed it in. This is limited to the `asg` tag which
just builds the Auto Scaling Group.

```
ansible-playbook build_env.yml \
  -e @vars/tp.yml \
  -e @vars/tp/preprod.yml \
  -e "ovc_version=5.4.0 deploy=true" \
  --vault-password-file ~/.ssh/.vault_pass.txt \
  --skip-tags=importers,rds,promo_engine,inventory_manager
```


#### Deploying Inventory Manager

Ensure the ansible beanstalk modules have been copied into the library directory for the play is run.
-   Modules: elasticbeanstalk_app.py, elasticbeanstalk_env.py, elasticbeanstalk_version.py
-   Can be downloaded or cloned from git: <https://github.com/hsingh/ansible-elastic-beanstalk>

The play can be included in a new environment deployment. It can also be run to update any changes in the environment (i.e. new version of Inventory Manager ). The promotion engine's version variable (im_version) will need to be defined as an extra variable ( -e ) in the playbook command.
The play can be included in a new environment deployment. It can also be run to update any changes in the environment (i.e. new version of Promotion Engine ). The promotion engine's version variable (pe_version) will need to be defined as an extra variable
( -e ) in the playbook command.

**Deploy Promo Engine only**

*Run from: Customer account*

```
ansible-playbook build_env.yml \
  -e @vars/demo.yml \
  -e @vars/demo/sit99.yml \
  -e pe_version=1.8.0 \
  --tags promo_engine
```


**Deploy Inventory Manager update only**

*Run from: Customer account*

```
ansible-playbook build_env.yml \
  -e @vars/demo.yml \
  -e @vars/demo/sit99.yml \
  -e im_version=2.3.0 \
  --tags inventory_manager
```

**Deploy Inventory Manager only**

*Run from: Customer account*

```
ansible-playbook build_env.yml \
  -e @vars/demo.yml \
  -e @vars/demo/sit99.yml \
  -e im_version=2.3.0 \
  -e im_update=true \
  --tags inventory_manager
```

**Deploy Mongo Only**

*Run from: Customer account*

```
ansible-playbook build_env.yml \
  -e @vars/demo.yml \
  -e @vars/demo/sit99.yml \
  -e @vars/demo.yml.encrypted \
  --tags mongodb_cm
```

### Maintenance

#### Patch files for web.xml

**Why patch files?** Simple sed would not always work in this situation so we're
guaranteeing a context to the patch. Patches can also be run with a variety of
'fuzz' levels to be compatible even if other parts nearby have changed. These
are found in `roles/oneview/files/cometd/`.

Importantly patch files **do not** modify the whole file like a template or copy
and so don't risk removing other updates that have been made to the same file.
These patches are run in the user_data.sh script which is used within the Launch
Configuration. **All patches** for **all environments** are included in **every
AMI** so it is important to rebuild the AMI if you change a patch.

-   Copy the latest version of the web.xml file into` oroginal.xml`, `preprod.xml`
    and `prod.xml`.

-   Attempt to patch the files using the existing patches, this way you can
    increase how liberal patch is if needed. Otherwise manually patch them.
```
    patch ./preprod.xml ./web.xml.patch.preprod
    patch ./prod.xml ./web.xml.patch.prod
```
-   Generate new strict patches from the diff's you can create now you have an
    original and a destination.
```
    diff -Naur original.xml prod.xml > ./web.xml.patch.prod
    diff -Naur original.xml preprod.xml > ./web.xml.patch.preprod
```
-   Remember to commit the .xml files and the patch files into git so anyone
    else can reproduce your work.

#### Non-patch environment files

These are not patch files or substitution processes, they require detailed
attention with each release. Unfortunately we cannot presume the latest changes
to any of these files until they are made and so no 'one size fits all' system
can be implemented without risk that the files change with new fields and that
these new fields also require changing before deployment.

##### File names

-   context.xml
-   database.php
-   setting_var.php
-   tools.properties
-   unifiedConfig.properties

##### Process to update

With each new release in UAT we should take the files generated there and update
the files held within Ansible to contain the same fields. One can compare the
two files as so (or with any other editor):
```
meld \
  context.xml.uat \
  roles/oneview/env_files/context.xml.prod
```
The two files should not be identical but the prod/preprod files should include
**all** of the fields that the UAT ones include.

##### Important note about context.xml

This file is a template but is added by file_glob. This means that **the
context.xml template lives in files/** which seems pretty odd. Please, **do not
move it to teplates/, it will not work**. Really, we've tested it by mistake.

### NGINX architecture

**Note:** There are better ways to do this. Unfortunately the combination of
which version of NGINX is used and the dashboard not supporting SSL means that
this is the only way we have found so far.

#### /ovcdashboard

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
```
Client (browser) -> /ovcdashboard (first proxy) -> /ovcdashboardproxy (second proxy) -> localhost:9080 (Apache)
```
This does mean that every request goes through the proxy **twice** which is a
bit messy.

![I'm sorry. I'm so, so sorry](https://i2.wp.com/s3-ak.buzzfeed.com/static/2014-05/tmp/webdr05/12/19/anigif_eaa6a580d8aece464ad6ec5fd8670b68-0.gif)

#### Jetty (/cometd and /)

This does conform to normal sane structure but does require the HTTP version to
be set as well as the Connection and Upgrade fields for CometD. Also, under /
it is important to remember that the proxy_set_header fields populate data about
where the connection originally came from (client, browser) not where it was
proxied (server, localhost).
```
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
```
### How machines become environment specific

Each AMI that is created is completely environment non-specific. Without making
any changes the AMI - if booted as a new machine - will not connect to an
environment and would not function as a usable OVC environment.

Within the AMi several configuration files are pre-populated, into the
directories which hold the running configuration files.
```
    /opt/jetty/webapps/context.xml
    /opt/jetty/webapps/context.xml.prod
    /opt/jetty/webapps/context.xml.preprod
```
When the Launch Configuration is created a set of User Data is added in to it
and when each machine is launched it runs that User Data. The User Data is a
shell script which in our case mostly moves some files around and can be found
in `scripts/user_data.sh`. Once the User Data script has been run the machine
will function within the environment.

### DNS architecture

We specifically redirect the wickes-tills.co.uk and travisperkins.com DNS
queries to the TP DNS servers. We do this with DNS servers built from an AMI.
If we ever have to produce a new one we simply create new instances of the AMI
and add those IP's to the DHCP config.

DNSMasq snippet:
```
    server=/wickes-tills.co.uk/172.31.101.101
    server=/wickes-tills.co.uk/172.31.103.112
    server=/wickes-tills.co.uk/172.31.101.103
    server=/wickes-tills.co.uk/172.31.104.102
    server=/travisperkins.com/172.31.101.101
    server=/travisperkins.com/172.31.103.112
    server=/travisperkins.com/172.31.101.103
    server=/travisperkins.com/172.31.104.102
    server=10.33.232.2
```
