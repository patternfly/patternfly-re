#!/bin/sh

# Email used to notify users release is available
EMAIL_PTNFLY=patternfly@redhat.com
EMAIL_PTNFLY_ANGULAR=patternfly-angular@redhat.com

# Git properties
GIT_USER_NAME=patternfly-build
GIT_USER_EMAIL=patternfly-build@redhat.com

# Common files
BOWER_JSON=bower.json
GEM_FILE=Gemfile
GRUNT_FILE_JS=Gruntfile.js
GRUNT_NGDOCS_TMPL=grunt-ngdocs-index.tmpl
HOME_HTML=source/index.html
KARMA_CONF_JS=karma.conf.js
NSP=node_modules/nsp/bin/nsp
PACKAGE_JSON=package.json
SHRINKWRAP_JSON=npm-shrinkwrap.json

# Prefix used to tag version bump (e.g., _bump-v3.15.0)
BUMP_TAG_PREFIX=_bump-v
BUMP_TAG_PREFIX_COUNT=`echo $BUMP_TAG_PREFIX | wc -c`

# Prefix used to tag release (e.g., v3.15.0)
RELEASE_TAG_PREFIX=v

# Repo slugs
REPO_SLUG_PTNFLY=patternfly/patternfly
REPO_SLUG_PTNFLY_ANGULAR=patternfly/angular-patternfly
REPO_SLUG_PTNFLY_ORG=patternfly/patternfly-org
REPO_SLUG_PTNFLY_ENG_RELEASE=patternfly/patternfly-eng-release
REPO_SLUG_RCUE=patternfly/rcue
REPO_SLUG_PTNFLY_WEB_COMPS=patternfly-webcomponents/patternfly-webcomponents

# Skip npm publish (for testing forks)
#SKIP_NPM_PUBLISH=1
