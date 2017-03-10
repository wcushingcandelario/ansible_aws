#!/usr/bin/env bash
set +x

OVC_VERSION='5.13.0'
GIT_BRANCH='release-5.13.0'
GIT_SHA1='055aa62357d4e09dea4d030997f14ed7a41c106f'
AMI_RELEASE='devops-autobuild'


echo $ANSIBLE_VAULT_PASSWORD > ~/.ssh/.vault_pass.txt

~/.local/bin/ansible-playbook build-new-ami.yml \
  -e @vars/vanilla.yml \
  -e "ovc_version=${OVC_VERSION}" \
  -e "s3_ovc_object=ovc-server-rolling-builds/${GIT_BRANCH}/${GIT_SHA1}" \
  -e "s3_bucket=ovc-release-provisioner" \
  -e "ovc_git_sha=${GIT_SHA1} ovc_circle_branch=${GIT_BRANCH} ami_release=${AMI_RELEASE}" \
  --vault-password-file="~/.ssh/.vault_pass.txt" \
  --skip-tags=importers,startjetty,rds_util \
  -vv
