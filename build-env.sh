#!/usr/bin/env bash
set +x

# Sleep 30s or the AMI is not available from the last play.
sleep 30

OVC_VERSION=5.15.0
CIRCLE_BRANCH='develop'
CIRCLE_SHA1='5b3bbde8ad6569f484a68d322c02f4250d9a22df'

# Used to save the AMI and work with the POS, typically `5.13.0-SNAPSHOT` or `5.11.1` format
#OVC_VERSION=$(cd $CIRCLE_ARTIFACTS; ls OvcInstallPackage-*.zip | cut -d- -f2)

if [ "${CIRCLE_BRANCH}" == 'develop' ]; then
  OVC_VERSION=${OVC_VERSION}-SNAPSHOT
fi

# Matches branches to automatic deployment into environment on commit.
#  develop -> devmysql
#  master -> qamysql
#  release-* -> rcmysql
#  hotfix-* -> rcmysql
#
#  Any and all of these environments can have a manual deployment whenever
# required of any particular git SHA. This is simply for automatic deployments.

ENVIRONMENT_NAME='unknown'
if [ "${CIRCLE_BRANCH}" == 'develop' ]; then
  ENVIRONMENT_NAME='devmysql'
elif [ "${CIRCLE_BRANCH}" == 'master' ]; then
  ENVIRONMENT_NAME='rcmysql'
elif [[ $CIRCLE_BRANCH == release-* ]]; then
  ENVIRONMENT_NAME='rcmysql'
elif [[ $CIRCLE_BRANCH == hotfix-* ]]; then
  ENVIRONMENT_NAME='rcmysql'
fi


if [ "${ENVIRONMENT_NAME}" !=  'unknown' ]; then

  echo $ANSIBLE_VAULT_PASSWORD > ~/.ssh/.vault_pass.txt

  ansible-playbook build_env.yml \
    -e "deploy_type=${ENVIRONMENT_NAME}" \
    -e "find_ami_sha=${CIRCLE_SHA1}" \
    -e 'ami_release=development' \
    -e @vars/demo.yml \
    -e @vars/demo/_development_environments.yml \
    -e "ovc_version=${OVC_VERSION}" \
    --vault-password-file ~/.ssh/.vault_pass.txt \
    --skip-tags "coreimporters,importers,rds,promo_engine,inventory_manager,mongodb_cm" \
    -vv


  if [ "${CIRCLE_BRANCH}" == 'develop' ]; then
    # Also deploy to the qamysql environment for develop commits.
    ENVIRONMENT_NAME='qamysql'

    ansible-playbook build_env.yml \
      -e "deploy_type=${ENVIRONMENT_NAME}" \
      -e "find_ami_sha=${CIRCLE_SHA1}" \
      -e 'ami_release=development' \
      -e @vars/demo.yml \
      -e @vars/demo/_development_environments.yml \
      -e "ovc_version=${OVC_VERSION}" \
      --vault-password-file ~/.ssh/.vault_pass.txt \
      --skip-tags "coreimporters,importers,rds,promo_engine,inventory_manager,mongodb_cm" \
      -vv
  fi

fi
