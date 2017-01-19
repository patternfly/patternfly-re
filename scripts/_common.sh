#!/bin/sh

# Build repo
#
build()
{
  echo "*** Building `pwd`"
  cd $BUILD_DIR

  # Grunt build
  if [ -s "$GRUNT_FILE_JS" ]; then
    if [ -s "$GEM_FILE" ]; then
      bundle exec grunt build
    else
      grunt build
    fi
  elif [ -s "$GULP_FILE_JS" ]; then
    gulp build
  fi
  check $? "Build failure"

  # NG Doc build
  if [ -s "$GRUNT_NGDOCS_TMPL" ]; then
    echo "*** Building ngDocs: `pwd`"
    grunt ngdocs:publish
    check $? "ngDocs build failure"
  fi

  # JS Doc build
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
    check $? "bower install failure"
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
  if [ -s "$NSP" -a -s "$SHRINKWRAP_JSON" ]; then
    node $NSP --shrinkwrap npm-shrinkwrap.json check --output summary
    check $? "shrinkwrap vulnerability found" warn
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
