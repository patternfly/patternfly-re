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
}

# Publish bower to webjar
#
# $1: Repo name
# $2: Version
publish_bower()
{
  echo "*** Publishing bower to webjar"

  # http://www.webjars.org/_bower/deploy?name=patternfly&version=3.18.1&channelId=e2627542-dd69-362d-8860-05704720017f
  curl -X POST "http://www.webjars.org/_bower/deploy?name=$1&version=$2&channelId=`random_guid`"
  check $? "publish bower webjar failure"

  printf "\n"
}

# Publish npm to webjar
#
# $1: Repo name
# $2: Version
publish_npm()
{
  echo "*** Publishing npm to webjar"

  # http://www.webjars.org/_npm/deploy?name=patternfly&version=3.18.1&channelId=e2627542-dd69-362d-8860-05704720017f
  curl -X POST "http://www.webjars.org/_npm/deploy?name=$1&version=$2&channelId=`random_guid`"
  check $? "publish npm webjar failure"

  printf "\n"
}

# Generate random GUIDs
#
# See: http://stackoverflow.com/questions/105034/create-guid-uuid-in-javascript/105074#105074
random_guid()
{
  NUM1=`random_number`
  NUM2=`random_number`
  RESULT1=`expr $NUM1 + $NUM2`

  NUM1=`random_number`
  NUM2=`random_number`
  NUM3=`random_number`
  NUM4=`random_number`
  RESULT2=`expr $NUM1 + $NUM2 + $NUM3 + $NUM4`

  echo "$RESULT1-`random_number`-`random_number`-`random_number`-$RESULT2"
}

# Generate random number
#
# See: http://www.mactricksandtips.com/2012/01/generate-random-numbers-in-terminalbash.html
random_number()
{
  echo "`od -vAn -N4 -tu < /dev/urandom | head -1 | awk '{print $1}'`"
}

usage()
{
cat <<- EEOOFF

    This script will publish webjars from published npm packages.

    sh [-x] $SCRIPT [-h|n] -a|n|p|x -v 3.15.0

    Example: sh $SCRIPT -p

    OPTIONS:
    h       Display this message (default)
    a       Angular PatternFly
    p       PatternFly
    v       The version number (e.g., 3.15.0)
    x       PatternFly NG

    SPECIAL OPTIONS:
    n       The package name (overrides -a|p switches)

EEOOFF
}

# main()
{
  default

  if [ "$#" -eq 0 ]; then
    usage
    exit 1
  fi

  while getopts han:pv:x c; do
    case $c in
      h) usage; exit 0;;
      a) REPO_NAME=$REPO_NAME_PTNFLY_ANGULAR;;
      n) OVERRIDE_REPO_NAME=$OPTARG;;
      p) REPO_NAME=$REPO_NAME_PTNFLY;;
      v) VERSION=$OPTARG;;
      x) REPO_NAME=$REPO_NAME_PTNFLY_NG;;
      \?) usage; exit 1;;
    esac
  done

  if [ -z "$VERSION" ]; then
    usage
    exit 1
  fi

  if [ -n "$OVERRIDE_REPO_NAME" ]; then
    REPO_NAME=$OVERRIDE_REPO_NAME
  fi

  publish_bower $REPO_NAME $VERSION
  publish_npm $REPO_NAME $VERSION
}
