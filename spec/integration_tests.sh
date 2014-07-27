#!/usr/bin/env bash

function cloneUnlessExists()
{
    REPOSRC=$1
    LOCALREPO=$2

    # We do it this way so that we can abstract if from just git later on.
    LOCALREPO_VC_DIR=$LOCALREPO/.git

    if [ ! -d $LOCALREPO_VC_DIR ]
    then
	git clone $REPOSRC $LOCALREPO
    else
	cd $LOCALREPO
	git pull $REPOSRC
    fi
}


function runIntegrationTests()
{
    cloneUnlessExists git@github.com:bugsnag/bugsnag-example-apps-tests.git integration
    cd integration
    bundle install
    rspec spec:$INTEGRATION_LANGUAGE
}
