#!/bin/bash

set -eo pipefail

cd ..

git config --global user.email $GH_EMAIL
git config --global user.name $GH_NAME

git clone $CIRCLE_REPOSITORY_URL $CIRCLE_BRANCH

ssh-add -D
ssh-add ~/.ssh/id_rsa_$PANTHEON_SSH_FINGERPRINT
ssh-keyscan -H -p $PANTHEON_CODESERVER_PORT $PANTHEON_CODESERVER >> ~/.ssh/known_hosts

cd $CIRCLE_BRANCH
git checkout $CIRCLE_BRANCH || git checkout --orphan $CIRCLE_BRANCH
HUGO_ENV=production hugo -v
git rm -rf .
mv public/* .
git remote add pantheon $PANTHEON_REMOTE
git add -A

if [ $CIRCLE_BRANCH == $SOURCE_BRANCH ]; then
  git commit -m "build ${CIRCLE_BRANCH} to pantheon: ${CIRCLE_SHA1}" --allow-empty
  git push -f pantheon $CIRCLE_BRANCH:master
else
  git commit -m "build ${CIRCLE_BRANCH} to pantheon remote ci-${CIRCLE_BUILD_NUM}: ${CIRCLE_SHA1}" --allow-empty
  terminus -n auth:login --machine-token="$TERMINUS_MACHINE_TOKEN"
  terminus multidev:create $PANTHEON_SITENAME.dev ci-$CIRCLE_BUILD_NUM
  git push -f pantheon $CIRCLE_BRANCH:ci-$CIRCLE_BUILD_NUM
  terminus auth:logout
fi