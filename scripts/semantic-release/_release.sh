#!/bin/sh

default()
{
  # Add paths to env (non-Travis build)
  if [ -z "$TRAVIS" ]; then
    PATH=/usr/local/bin:/usr/bin:/bin:$PATH
    export PATH
  fi

  SCRIPT=`basename $0`
  SCRIPT_DIR=`dirname $0`
  SCRIPT_DIR=`cd $SCRIPT_DIR; pwd`

  . $SCRIPT_DIR/../_env.sh
  . $SCRIPT_DIR/../_common.sh
  . $SCRIPT_DIR/../release/_common.sh

  BRANCH=$RELEASE_BRANCH
  BRANCH_DIST=$RELEASE_DIST_BRANCH
  BUILD_DIR=$TRAVIS_BUILD_DIR
  TMP_DIR="/tmp/patternfly-releases"
}

# Bump version number in bower.json
#
bump_bower()
{
  echo "*** Bumping version in $BOWER_JSON to $VERSION"
  cd $BUILD_DIR

  if [ ! -s "$BOWER_JSON" ]; then
    return
  fi

  # For testing forks without npm publish, set REPO_FORK=1 via local env
  if [ -n "$REPO_FORK" ]; then
    PKG_PTNFLY="git://$REPO_URL_PTNFLY#$BRANCH_DIST"
    PKG_PTNFLY_ANGULAR="git://$REPO_URL_PTNFLY_ANGULAR#$BRANCH_DIST"
  else
    PKG_PTNFLY=`npm show patternfly version`
    PKG_PTNFLY_ANGULAR=`npm show angular-patternfly version`
  fi

  if [ -n "$PTNFLY" ]; then
    sed "s|\"version\":.*|\"version\": \"$VERSION\",|" $BOWER_JSON > $BOWER_JSON.tmp
  elif [ -n "$PTNFLY_ANGULAR" ]; then
    sed "s|\"version\":.*|\"version\": \"$VERSION\",|" $BOWER_JSON > $BOWER_JSON.tmp
  elif [ -n "$PTNFLY_NG" ]; then
    sed "s|\"version\":.*|\"version\": \"$VERSION\",|" $BOWER_JSON | \
    sed "s|\"patternfly\":.*|\"patternfly\": \"$PKG_PTNFLY\"|" > $BOWER_JSON.tmp
  fi
  check $? "Version bump failure"

  if [ -s "$BOWER_JSON.tmp" ]; then
    mv $BOWER_JSON.tmp $BOWER_JSON
    check $? "File move failure"
  fi
}

# Bump version number in JavaScript
#
bump_js()
{
  echo "*** Bumping version in $PTNFLY_SETTINGS_JS to $VERSION"
  cd $BUILD_DIR

  if [ -n "$PTNFLY" ]; then
    sed 's|version:.*|version: \"$VERSION\",|' $PTNFLY_SETTINGS_JS > $PTNFLY_SETTINGS_JS.tmp
    check $? "Version bump failure"

    mv $PTNFLY_SETTINGS_JS.tmp $PTNFLY_SETTINGS_JS
    check $? "File move failure"
  fi
}

# Clean shrinkwrap
#
clean_shrinkwrap()
{
  echo "*** Cleaning $SHRINKWRAP_JSON"
  cd $BUILD_DIR

  if [ -s $SHRINKWRAP_JSON ]; then
    rm -f $SHRINKWRAP_JSON
  fi
}

# Commit changes prior to bower verify step
#
commit()
{
  echo "*** Committing changes"
  cd $BUILD_DIR

  git add -u
  git commit -m "Updating files modified by Travis build"
}

dist_copy()
{
  echo "*** Copying files to dist"
  cd $BUILD_DIR

  cp $PACKAGE_JSON $SHRINKWRAP_JSON dist
  check $? "copy failure"
}

# Shrink wrap npm and run vulnerability test
#
shrinkwrap()
{
  echo "*** Shrink wrapping $SHRINKWRAP_JSON"
  cd $BUILD_DIR

  if [ -z "$PTNFLY_ENG_RELEASE" ]; then
    # Only include production dependencies with shrinkwrap
    npm prune --production

    npm shrinkwrap
    check $? "npm shrinkwrap failure"

    # Restore all packages for testing with karma, nsp, etc.
    npm install
  fi
}

usage()
{
cat <<- EEOOFF

    This script will bump bower version number, shrinkwrap, test, and verify npm/bower installs

    sh [-x] $SCRIPT [-h|b|f|n] -a|e|p|w|x -v <version>

    Example: sh $SCRIPT -v 3.15.0 -p

    OPTIONS:
    h       Display this message (default)
    a       Angular PatternFly
    e       PatternFly Eng Release
    p       PatternFly
    v       The version number (e.g., 3.15.0)
    w       PatternFly Web Components
    x       Patternfly NG

    SPECIAL OPTIONS:
    b       The branch to release (e.g., $NEXT_BRANCH)
    f       Run against repo fork matching local username (e.g., `whoami`/patternfly)
    n       Release PF 'next' branches (e.g., PF4 alpha, beta, etc.)

EEOOFF
}

# Verify npm and bower installs prior to publish step
#
# $1: Verify directory
# $2: Build directory
verify()
{
  echo "*** Verifying install"

  rm -rf $1
  mkdir -p $1
  cd $1

  if [ -s "$2/$PACKAGE_JSON" ]; then
    npm install $2
    check $? "npm install failure"

    if [ ! -d "$1"/node_modules ]; then
      check 1 "npm install failure: node_modules directory expected"
    fi
  fi
  if [ -s "$2/$BOWER_JSON" ]; then
    cp $2/$BOWER_JSON .
    bower install
    check $? "bower install failure"
  fi
}

# main()
{
  default

  if [ "$#" -eq 0 ]; then
    usage
    exit 1
  fi

  while getopts hab:efnpv:wx c; do
    case $c in
      h) usage; exit 0;;
      a) PTNFLY_ANGULAR=1;;
      b) BRANCH=$OPTARG;;
      e) PTNFLY_ENG_RELEASE=1;;
      f) REPO_FORK=1;;
      n) BRANCH_DIST=$NEXT_DIST_BRANCH;;
      p) PTNFLY=1;;
      v) VERSION=$OPTARG;;
      w) PTNFLY_WC=1;;
      x) PTNFLY_NG=1;;
      \?) usage; exit 1;;
    esac
  done

  # Source env.sh afer setting REPO_FORK
  if [ -n "$REPO_FORK" ]; then
    default
  fi

  if [ -n "$PTNFLY_ANGULAR" ]; then
    REPO_SLUG=$REPO_SLUG_PTNFLY_ANGULAR
    VERIFY_DIR="$TMP_DIR/angular-patternfly-verify"
  fi
  if [ -n "$PTNFLY_ENG_RELEASE" ]; then
    REPO_SLUG=$REPO_SLUG_PTNFLY_ENG_RELEASE
    VERIFY_DIR="$TMP_DIR/patternfly-eng-release-verify"
  fi
  if [ -n "$PTNFLY" ]; then
    REPO_SLUG=$REPO_SLUG_PTNFLY
    VERIFY_DIR="$TMP_DIR/patternfly-verify"
  fi
  if [ -n "$PTNFLY_WC" ]; then
    REPO_SLUG=$REPO_SLUG_PTNFLY_WC
    VERIFY_DIR="$TMP_DIR/patternfly-webcomponents-verify"
  fi
  if [ -n "$PTNFLY_NG" ]; then
    REPO_SLUG=$REPO_SLUG_PTNFLY_NG
    VERIFY_DIR="$TMP_DIR/patternfly-ng"
  fi

  if [ -z "$VERSION" -o -z "$REPO_SLUG" ]; then
    usage
    exit 1
  fi

  clean_shrinkwrap # Remove shrinkwrap prior to install
  bump_bower
  bump_js
  build_install
  build
  shrinkwrap
  build_test
  commit # Changes must be committed prior to bower verify step

  if [ -n "$PTNFLY_NG" ]; then
    verify $VERIFY_DIR $BUILD_DIR/dist
    dist_copy
  else
    verify $VERIFY_DIR $BUILD_DIR
  fi
}
