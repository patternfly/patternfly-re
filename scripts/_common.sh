#!/bin/sh

# Build repo
#
build()
{
  echo "*** Building `pwd`"
  cd $BUILD_DIR

  # NPM build
  JUNK=`npm run | awk -F' ' '{print $1}' | grep '^build$'`

  if [ "$?" -eq 0 ]; then
    npm run build
  elif [ -s "$GRUNT_FILE_JS" ]; then
    # Grunt build
    JUNK=`grep production "$GRUNT_FILE_JS"`
    if [ "$?" -eq 0 ]; then
      PRODUCTION=:production
    fi
    if [ -s "$GEM_FILE" ]; then
      bundle exec grunt build$PRODUCTION
    else
      grunt build$PRODUCTION
    fi
  elif [ -s "$GULP_FILE_JS" ]; then
    gulp build
  fi
  check $? "Build failure"

  # NPM demo build for patternfly-ng
  JUNK=`npm run | awk -F' ' '{print $1}' | grep '^build:demo$'`

  if [ "$?" -eq 0 ]; then
    npm run build:demo
    check $? "Demo build failure"
  fi

  # NG Doc build for angular patternfly
  if [ -s "$GRUNT_NGDOCS_TMPL" ]; then
    echo "*** Building ngDocs: `pwd`"
    grunt ngdocs:publish
    check $? "ngDocs build failure"
  fi

  # JS Doc build for webcomponents
  if [ -s "$JSDOC_CONF_JSON" ]; then
    echo "*** Building jsDoc: `pwd`"
    gulp doc
    check $? "jsDoc build failure"
  fi
}

# Install build dependencies
#
build_install()
{
  echo "*** Intsalling build dependencies"
  cd $BUILD_DIR

  # Bundle install
  if [ -s "$GEM_FILE" ]; then
    bundle install
    check $? "bundle install failure"
  fi

  # NPM install
  if [ -s "$PACKAGE_JSON" ]; then
    npm install
    check $? "npm install failure"
  fi

  # Bower install
  if [ -s "$BOWER_JSON" ]; then
    bower install
    checkval=$?
    if [ $checkval -ne 0 ]; then
      echo "*** $BOWER_JSON contents:"
      cat $BOWER_JSON
      check $checkval "bower install failure"
    fi
  fi
}

# Test build
build_test()
{
  echo "*** Testing build"
  cd $BUILD_DIR

  if [ -s "$KARMA_CONF_JS" ]; then
    npm test
    check $? "npm test failure"
  fi
  if [ -s "$NSP" ]; then
    node $NSP check --output summary
    check $? "package.json vulnerability found" warn
  fi
}

# Check errors
#
# $1: Exit status
# $2: Error message
# $3: Show warning
check()
{
  if [ "$1" != 0 ]; then
    if [ "$3" = "warn" ]; then
      printf "\n"
      echo "*** Warning: $2"
    else
      printf "\n"
      echo "*** Error: $2"
      exit $1
    fi
  fi
}

# Setup env for use with GitHub
#
git_setup()
{
  echo "*** Setting up Git env"
  cd $BUILD_DIR

  git config user.name $GIT_USER_NAME
  git config user.email $GIT_USER_EMAIL
  git config --global push.default simple

  # Add upstream as a remote
  git remote rm upstream
  git remote add upstream https://$AUTH_TOKEN@github.com/$TRAVIS_REPO_SLUG.git
  check $? "git add remote failure"

  # Reconcile detached HEAD -- name must not be ambiguous with tags
  git checkout -B $TRAVIS_BRANCH-local
  check $? "git checkout failure"

  # Fetch to test if tag exists
  git fetch --tags
  check $? "Fetch tags failure"
}

# Shrink wrap npm and run vulnerability test
#
# The recommended use-case for npm-shrinkwrap.json is applications deployed through the publishing process on the
# registry: for example, daemons and command-line tools intended as global installs or devDependencies. It's strongly
# discouraged for library authors to publish this file, since that would prevent end users from having control over
# transitive dependency updates.
#
# See https://docs.npmjs.com/files/shrinkwrap.json
shrinkwrap()
{
  echo "*** Shrink wrapping $SHRINKWRAP_JSON"
  cd $BUILD_DIR

  # Only include production dependencies with shrinkwrap
  npm prune --production

  npm shrinkwrap
  check $? "npm shrinkwrap failure"

  # Restore dependencies
  npm install

  if [ -s "$NSP" -a -s "$SHRINKWRAP_JSON" ]; then
    node $NSP --shrinkwrap npm-shrinkwrap.json check --output summary
    check $? "shrinkwrap vulnerability found" warn
  fi
}
