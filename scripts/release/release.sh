#!/bin/sh

default()
{
  # Add paths to env (non-Travis build)
  if [ -z "$TRAVIS" ]; then
    PATH=/bin:/usr/bin:/usr/local/bin:$PATH
    export PATH
  fi

  SCRIPT=`basename $0`
  SCRIPT_DIR=`dirname $0`
  SCRIPT_DIR=`cd $SCRIPT_DIR; pwd`

  . $SCRIPT_DIR/../_env.sh
  . $SCRIPT_DIR/../_common.sh
  . $SCRIPT_DIR/_common.sh

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

  if [ -n "$PTNFLY" ]; then
    sed "s|\"version\":.*|\"version\": \"$VERSION\",|" $BOWER_JSON > $BOWER_JSON.tmp
  elif [ -n "$PTNFLY_ANGULAR" ]; then
    sed "s|\"version\":.*|\"version\": \"$VERSION\",|" $BOWER_JSON | \
    sed "s|\"patternfly\":.*|\"patternfly\": \"~$VERSION\"|" > $BOWER_JSON.tmp
  elif [ -n "$PTNFLY_ORG" ]; then
    sed "s|\"version\":.*|\"version\": \"$VERSION\",|" $BOWER_JSON | \
    sed "s|\"patternfly\":.*|\"patternfly\": \"~$VERSION\",|" | \
    sed "s|\"angular-patternfly\":.*|\"angular-patternfly\": \"~$VERSION\",|" > $BOWER_JSON.tmp
  elif [ -n "$PTNFLY_RCUE" ]; then
    sed "s|\"version\":.*|\"version\": \"$VERSION\",|" $BOWER_JSON | \
    sed "s|\"patternfly\":.*|\"patternfly\": \"~$VERSION\"|" > $BOWER_JSON.tmp
  elif [ -n "$PTNFLY_ENG_RELEASE" ]; then
    sed "s|\"version\":.*|\"version\": \"$VERSION\",|" $BOWER_JSON > $BOWER_JSON.tmp
  fi
  check $? "Version bump failure"

  if [ -s "$BOWER_JSON.tmp" ]; then
    mv $BOWER_JSON.tmp $BOWER_JSON
    check $? "File move failure"
  fi
}

# Bump version number in package.json
#
bump_package()
{
  echo "*** Bumping version in $PACKAGE_JSON to $VERSION"
  cd $BUILD_DIR

  if [ -n "$PTNFLY" ]; then
    sed "s|\"version\":.*|\"version\": \"$VERSION\",|" $PACKAGE_JSON |
    sed "s|\"patternfly-eng-release\":.*|\"patternfly-eng-release\": \"~$VERSION\",|" > $PACKAGE_JSON.tmp
  elif [ -n "$PTNFLY_ANGULAR" ]; then
    sed "s|\"version\":.*|\"version\": \"$VERSION\",|" $PACKAGE_JSON | \
    sed "s|\"patternfly\":.*|\"patternfly\": \"~$VERSION\"|" |
    sed "s|\"patternfly-eng-release\":.*|\"patternfly-eng-release\": \"~$VERSION\"|" > $PACKAGE_JSON.tmp
  elif [ -n "$PTNFLY_ORG" ]; then
    sed "s|\"version\":.*|\"version\": \"$VERSION\",|" $PACKAGE_JSON |
    sed "s|\"patternfly-eng-release\":.*|\"patternfly-eng-release\": \"~$VERSION\"|" > $PACKAGE_JSON.tmp
  elif [ -n "$PTNFLY_RCUE" ]; then
    sed "s|\"version\":.*|\"version\": \"$VERSION\",|" $PACKAGE_JSON | \
    sed "s|\"patternfly\":.*|\"patternfly\": \"~$VERSION\"|"|
    sed "s|\"patternfly-eng-release\":.*|\"patternfly-eng-release\": \"~$VERSION\"|" > $PACKAGE_JSON.tmp
  elif [ -n "$PTNFLY_ENG_RELEASE" ]; then
    sed "s|\"version\":.*|\"version\": \"$VERSION\",|" $PACKAGE_JSON > $PACKAGE_JSON.tmp
  elif [ -n "$PTNFLY_WEB_COMPS" ]; then
    sed "s|\"version\":.*|\"version\": \"$VERSION\",|" $PACKAGE_JSON > $PACKAGE_JSON.tmp
  fi
  check $? "Version bump failure"

  if [ -s "$PACKAGE_JSON.tmp" ]; then
    mv $PACKAGE_JSON.tmp $PACKAGE_JSON
    check $? "File move failure"
  fi
}

# Bump version in home page
#
bump_home()
{
  echo "*** Bumping version in $HOME_HTML to $VERSION"
  cd $BUILD_DIR

  if [ -n "$PTNFLY_ORG" ]; then
    PREFIX="<p class=\"version wow fadeIn\" data-wow-delay=\"1500ms\">Version"
    sed "s|$PREFIX.*|$PREFIX $VERSION</p>|" $HOME_HTML > $HOME_HTML.tmp
    check $? "Version bump failure"
  fi
  if [ -s "$HOME_HTML.tmp" ]; then
    mv $HOME_HTML.tmp $HOME_HTML
    check $? "File move failure"
  fi
}

# Clean cache
#
clean_cache()
{
  echo "*** Cleaning npm and bower cache"
  cd $BUILD_DIR

  # Clean npm and bower installs
  npm cache clean
  bower cache clean
}

# Clean shrinkwrap
#
clean_shrinkwrap()
{
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
  git commit -m "Bumped version number to $VERSION"
}

# Push changes to remote repo
#
push()
{
  echo "*** Pushing changes to $REPO_SLUG"
  cd $BUILD_DIR

  git push --set-upstream origin $BRANCH --force
  check $? "git push failure"

  echo "*** Changes pushed to the $BRANCH branch of $REPO_SLUG"
  echo "*** Review changes and create a PR via GitHub"
}

# Shrink wrap npm and run vulnerability test
#
shrinkwrap()
{
  echo "*** Shrink wrapping $SHRINKWRAP_JSON"
  cd $BUILD_DIR

  # Only include production dependencies with shrinkwrap
  npm prune --production

  npm shrinkwrap
  check $? "npm shrinkwrap failure"

  # Restore all packages for testing with karma, nsp, etc.
  npm install
}

usage()
{
cat <<- EEOOFF

    This script will bump repo version numbers, build, shrinkwrap, test, install, push to GitHub.

    Note: After changes are pushed, a PR will need to be created via GitHub.

    sh [-x] $SCRIPT [-h] -a|e|f|o|p|r|s|w -v <version>

    Example: sh $SCRIPT -v 3.15.0 -p

    OPTIONS:
    h       Display this message (default)
    a       Angular PatternFly
    e       Patternfly Eng Release
    f       Force push new branch to GitHub (e.g., bump-v3.15.0)
    o       PatternFly Org
    p       PatternFly
    r       PatternFly RCUE
    s       Skip new clone and clean cache to rebuild previously created repo
    v       The version number (e.g., 3.15.0)
    w       Patternfly Web Components

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
    bower install $2/$BOWER_JSON
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

  while getopts haefoprsv:w c; do
    case $c in
      h) usage; exit 0;;
      a) PTNFLY_ANGULAR=1;
         BUILD_DIR=$TMP_DIR/angular-patternfly;
         REPO_SLUG=$REPO_SLUG_PTNFLY_ANGULAR;
         VERIFY_DIR="$TMP_DIR/angular-patternfly-verify";;
      e) PTNFLY_ENG_RELEASE=1;
         BUILD_DIR=$TMP_DIR/patternfly-eng-release;
         REPO_SLUG=$REPO_SLUG_PTNFLY_ENG_RELEASE;
         VERIFY_DIR="$TMP_DIR/patternfly-eng-release-verify";;
      f) PUSH=1;;
      o) PTNFLY_ORG=1;
         BUILD_DIR=$TMP_DIR/patternfly-org;
         REPO_SLUG=$REPO_SLUG_PTNFLY_ORG;
         VERIFY_DIR="$TMP_DIR/patternfly-org-verify";;
      p) PTNFLY=1;
         BUILD_DIR=$TMP_DIR/patternfly;
         REPO_SLUG=$REPO_SLUG_PTNFLY;
         VERIFY_DIR="$TMP_DIR/patternfly-verify";;
      r) PTNFLY_RCUE=1;
         BUILD_DIR=$TMP_DIR/rcue;
         REPO_SLUG=$REPO_SLUG_RCUE;
         VERIFY_DIR="$TMP_DIR/rcue-verify";;
      s) SKIP_SETUP=1;;
      v) VERSION=$OPTARG;
         BRANCH=bump-v$VERSION;;
      w) PTNFLY_WEB_COMPS=1;
         BUILD_DIR=$TMP_DIR/patternfly-webcomponents;
         REPO_SLUG=$REPO_SLUG_PTNFLY_WEB_COMPS;
         VERIFY_DIR="$TMP_DIR/patternfly-webcomponents-verify";;
      \?) usage; exit 1;;
    esac
  done

  if [ -z "$VERSION" -o -z "$REPO_SLUG" ]; then
    usage
    exit 1
  fi

  # Release from the latest repo clone or Travis build
  if [ -n "$TRAVIS_BUILD_DIR" ]; then
    BUILD_DIR=$TRAVIS_BUILD_DIR
  fi
  if [ -z "$SKIP_SETUP" ]; then
    setup_repo $REPO_SLUG $BRANCH
    clean_cache
  fi

  clean_shrinkwrap # Remove shrinkwrap prior to install
  bump_bower
  bump_package
  bump_home
  build_install
  build

  if [ -n "$PTNFLY" -o -n "$PTNFLY_ANGULAR" -o -n "$PTNFLY_RCUE" ]; then
    shrinkwrap
  fi

  build_test
  commit # Commit changes prior to bower verify step
  verify $VERIFY_DIR $BUILD_DIR

  # Push changes to remote branch
  if [ -n "$PUSH" ]; then
    push
  fi
  if [ -z "$TRAVIS" ]; then
    echo "*** Run publish-npm.sh to publish npm after PR has been merged"
    echo "*** Remove $TMP_DIR directory manually after testing"
  fi
}
