#!/usr/bin/env bash

# Exit if any command fails.
set -e

export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

function clone_unless_exists()
{
    git config user.email "buildbox@bugsnag.com"
    git config user.name "Buildbox Bugsnag"

    REPOSRC=$1
    LOCALREPO=$2

    # We do it this way so that we can abstract if from just git later on.
    LOCALREPO_VC_DIR=$LOCALREPO/.git

    if [ ! -d $LOCALREPO_VC_DIR ]
    then
	git clone $REPOSRC $LOCALREPO
	cd $LOCALREPO
    else
	cd $LOCALREPO
	git pull $REPOSRC
    fi
}


function run_integration_tests()
{
    clone_unless_exists git@github.com:bugsnag/bugsnag-example-apps-tests.git integration
    ./setup.sh
    rspec spec/$INTEGRATION_LANGUAGE
}

run_integration_tests
