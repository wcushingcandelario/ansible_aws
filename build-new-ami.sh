#!/usr/bin/env bash
set +x

echo $ANSIBLE_VAULT_PASSWORD > ~/.ssh/.vault_pass.txt

OVC_VERSION='5.13.0'
FIND_OVC_VERSION=${OVC_VERSION}
EXT_VERSION="5.13.0-28-g0c05cd7"
GIT_BRANCH='release-5.13.0'
FIND_AMI_BRANCH=${GIT_BRANCH}
GRADLE_BRANCH='rcs'
GIT_SHA1='055aa62357d4e09dea4d030997f14ed7a41c106f'
AMI_RELEASE='devops-autobuild'

~/.local/bin/ansible-playbook build-new-ami.yml \
  -e @vars/vanilla.yml \
  -e "ovc_version=${OVC_VERSION}" \
  -e "s3_ovc_object=ovc-server-rolling-builds/${GIT_BRANCH}/${GIT_SHA1}" \
  -e "s3_bucket=ovc-release-provisioner" \
  -e "ovc_git_sha=${GIT_SHA1} ovc_circle_branch=${GIT_BRANCH} ami_release=${AMI_RELEASE}" \
  --vault-password-file="~/.ssh/.vault_pass.txt" \
  --skip-tags=importers,startjetty,rds_util \
  -vv

GIT_SHA1='0c05cd7db65221e9fd527929203aec29348c8f70'

cd build/ansible/ansible
~/.local/bin/ansible-playbook build-new-ami.yml \
  -e @vars/tp.yml.encrypted \
  -e @vars/tp.yml \
  -e "ovc_version=${OVC_VERSION} find_ovc_version=${FIND_OVC_VERSION} tp_extension_version=${EXT_VERSION}" \
  -e 's3_bucket_customer=ovc-gradle-repo' \
  -e "s3_full_zip_prefix=${GRADLE_BRANCH}/com/oneview/TPCustomPackage/" \
  -e 'staffDiscount_bucketName=BOB' \
  -e "ovc_git_sha=${CIRCLE_SHA1} ovc_circle_branch=${GIT_BRANCH} ami_release=${AMI_RELEASE}" \
  -e "find_ami_branch=${FIND_AMI_BRANCH}" \
  -e 'use_public_ip=Yes' \
  --vault-password-file="~/.ssh/.vault_pass.txt" \
  --skip-tags=importers,import_custom_db,startjetty,rds_util \
  -vv
