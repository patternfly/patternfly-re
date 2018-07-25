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

build_aot()
{
  echo "*** Testing AOT build"
  cd $BUILD_DIR

  # NPM script build
  JUNK=`npm run | awk -F' ' '{print $1}' | grep '^build:demo$'`

  if [ "$?" -eq 0 ]; then
    npm run build:demo
    check $? "*** AOT compilation failure"
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

# Push changes
#
publish_branch()
{
  # Ensure we don't push to <branch>-dist-dist...
  case "$TRAVIS_BRANCH" in
    *-dist ) return;;
  esac

  if [ -n "$PTNFLY_NG" ]; then
    sh -x $SCRIPT_DIR/_publish-branch.sh -c -d -o -s
    check $? "Publish failure"
  elif [ -n "$PTNFLY" -o -n "$PTNFLY_ANGULAR" -o -n "$PTNFLY_WC" ]; then
    sh -x $SCRIPT_DIR/_publish-branch.sh -c -d
    check $? "Publish failure"
  fi
}

usage()
{
cat <<- EEOOFF

    This script will build, shrinkwrap, test, and verify npm/bower installs.

    Note: Currently, only PatternFly and Angular PatternFly have a $SHRINKWRAP_JSON file.

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

  # build:demo is already run
  #if [ -n "$PTNFLY_NG" ]; then
  #  build_aot
  #fi

  sh -x $SCRIPT_DIR/_regression-test.sh
  check $? "Regression test failure"

  # It's strongly discouraged for library authors to publish shrinkwrap.json, since that would prevent end users from
  # having control over transitive dependency updates. See https://docs.npmjs.com/files/shrinkwrap.json
  #
  if [ -n "$PTNFLY" -o -n "$PTNFLY_ANGULAR" ]; then
    shrinkwrap
  fi

  verify
  publish_branch
}
