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
  . $SCRIPT_DIR/_common.sh

  BUILD_DIR=$TRAVIS_BUILD_DIR
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

# Push changes
#
publish_branch()
{
  # Ensure we don't push to <branch>-dist-dist...
  case "$TRAVIS_BRANCH" in
    *-dist ) return;;
  esac

  if [ -n "$PTNFLY_NG" ]; then
    sh -x $SCRIPT_DIR/_publish-branch.sh -c -d -o
    check $? "Publish failure"
  elif [ -n "$PTNFLY" -o -n "$PTNFLY_ANGULAR" -o -n "$PTNFLY_WC" ]; then
    sh -x $SCRIPT_DIR/_publish-branch.sh -c -d
    check $? "Publish failure"
  fi
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

    if [ -s "$NSP" -a -s "$SHRINKWRAP_JSON" ]; then
      node $NSP --shrinkwrap npm-shrinkwrap.json check --output summary
      check $? "shrinkwrap vulnerability found" warn
    fi
  fi
}

usage()
{
cat <<- EEOOFF

    This script will bump the version number in PatternFly JS, shrinkwrap, test, and verify npm/bower installs

    sh [-x] $SCRIPT [-h] -a|e|p|w|x

    Example: sh $SCRIPT -p

    OPTIONS:
    h       Display this message (default)
    a       Angular PatternFly
    e       PatternFly Eng Release
    p       PatternFly
    w       PatternFly Web Components
    x       PatternFly NG

EEOOFF
}

verify()
{
  sh -x $SCRIPT_DIR/_verify.sh $SWITCH
  check $? "Verify failure"
}

# main()
{
  default

  if [ "$#" -eq 0 ]; then
    usage
    exit 1
  fi

  while getopts haepwx c; do
    case $c in
      h) usage; exit 0;;
      a) PTNFLY_ANGULAR=1;
         SWITCH=-a;;
      e) PTNFLY_ENG_RELEASE=1;
         SWITCH=-e;;
      p) PTNFLY=1;
         SWITCH=-p;;
      w) PTNFLY_WC=1;
         SWITCH=-w;;
      x) PTNFLY_NG=1;
         SWITCH=-x;;
      \?) usage; exit 1;;
    esac
  done

  clean_shrinkwrap
  build_install
  build
  build_test
  shrinkwrap
  verify
  publish_branch
}
