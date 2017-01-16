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
}

# Publish to webjar
#
# $1: Repo name
# $2: Version
publish_webjar()
{
  echo "*** Publishing webjar"

  curl -X POST "http://www.webjars.org/_npm/deploy?name=$1&version=$2&channelId=123"
  check $? "webjar publish failure"
}

usage()
{
cat <<- EEOOFF

    This script will publish webjars from published npm packages.

    sh [-x] $SCRIPT [-h] -a|p

    Example: sh $SCRIPT -p

    OPTIONS:
    h       Display this message (default)
    a       Angular PatternFly
    p       PatternFly

EEOOFF
}

# main()
{
  default

  if [ "$#" -eq 0 ]; then
    usage
    exit 1
  fi

  while getopts hapv: c; do
    case $c in
      h) usage; exit 0;;
      a) REPO_NAME=$REPO_NAME_PTNFLY_ANGULAR;;
      p) REPO_NAME=$REPO_NAME_PTNFLY;;
      v) VERSION=$OPTARG;;
      \?) usage; exit 1;;
    esac
  done

  if [ -z "$VERSION" ]; then
    usage
    exit 1
  fi

  publish_webjar $REPO_NAME $VERSION
}
