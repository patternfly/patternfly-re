#!/bin/sh

default()
{
  PATH=/usr/local/bin:/usr/bin:/bin:$PATH
  export PATH
  
  SCRIPT=`basename $0`
  SCRIPT_DIR=`dirname $0`
  SCRIPT_DIR=`cd $SCRIPT_DIR; pwd`

  . $SCRIPT_DIR/../_env.sh
  . $SCRIPT_DIR/../_common.sh
  . $SCRIPT_DIR/_common.sh
}

# Ensure repo tag exists
#
# Recently created tags may not be available, yet?
# See: https://stackoverflow.com/questions/32638958/uploading-releasenotes-text-to-github-using-github-api-fails-sometimes
#
# $1: Repo slug
# $2: Release tag
#
check_tag()
{
  echo "*** Checking for tag"

  RETURN_STATUS=`curl -s -w "%{http_code}" "https://api.github.com/repos/$1/git/refs/tags/$2" -o /dev/null`

  if [ "$RETURN_STATUS" -ne "200" ]; then
    check 1 "** Cannot find tag\nEnsure release has been published via GitHub"
  fi
}

# Create a release
#
# $1: Repo slug
# $2: Release tag
# $3: Release branch
# $4: Release notes
create_release()
{
  echo "*** Creating release"

  RETURN_STATUS=`curl -s -w "%{http_code}" \
    -X POST -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: token $GH_TOKEN" "https://api.github.com/repos/$1/releases" \
    -d "{\"tag_name\": \"$2\", \"target_commitish\": \"$3\", \"name\": \"$2\", \"body\": \"$4\"}" -o /dev/null`

  if [ "$RETURN_STATUS" -eq "422" ]; then
    echo "*** Release notes already exist"
    exit 0
  elif [ "$RETURN_STATUS" -ne "201" ]; then
    check 1 "*** Could not create release notes.\nEnsure release has been published via GitHub."
  fi
}

# Check prerequisites before continuing
#
prereqs()
{
  if [ -z "$GH_TOKEN" ]; then
    check 1 "*** GH_TOKEN env variable not set"
  fi
}

usage()
{
cat <<- EEOOFF
    This script will publish release notes to GitHub.

    sh [-x] $SCRIPT [-h] -r -v <version>

    Example: sh $SCRIPT -v 3.15.0 -r

    OPTIONS:
    h       Display this message (default)
    r       RCUE

EEOOFF
}

# main()
{
  default

  if [ "$#" -eq 0 ]; then
    usage
    exit 1
  fi

  while getopts hrv: c; do
    case $c in
      h) usage; exit 0;;
      r) RCUE=1;
         BRANCH=$RELEASE_BRANCH;
         REPO_SLUG=$REPO_SLUG_RCUE;;
      v) VERSION=$OPTARG;
         RELEASE_TAG=v$VERSION;;
      \?) usage; exit 1;;
    esac
  done

  if [ -z "$VERSION" -o -z "$REPO_SLUG" ]; then
    usage
    exit 1
  fi

  if [ -n "$RCUE" ]; then
    RELEASE_NOTES="# Release Notes<br/><br/>See the [PatternFly Release Notes](https://github.com/patternfly/patternfly/releases/tag/$RELEASE_TAG)"
  fi

  prereqs
  check_tag $REPO_SLUG $RELEASE_TAG
  create_release $REPO_SLUG $RELEASE_TAG $BRANCH "$RELEASE_NOTES"
}
