#!/bin/bash
curl https://raw.githubusercontent.com/bugsnag/license-audit/master/config/decision_files/global.yml -o config/decisions.yml
curl https://raw.githubusercontent.com/bugsnag/license-audit/master/config/decision_files/bugsnag-ruby.yml >> config/decisions.yml

bundle install
license_finder --decisions-file=config/decisions.yml
