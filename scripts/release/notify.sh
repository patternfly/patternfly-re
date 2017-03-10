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

  TMP_DIR=/tmp/$SCRIPT.$$
  TMP_FILE=notify.txt
}

# Send email notifying users a new release is available
#
# $1: Repo slug
# $2: Subject
# $3: Email list
email()
{
  echo "*** Notifying email list"
  mkdir -p $TMP_DIR

cat > $TMP_DIR/$TMP_FILE <<- EEOOFF
The UXD team is proud to announce the $VERSION release of $2. This release includes the following changes.

$RELEASE_NOTES

Check out the $2 $VERSION Release Notes for more details:
https://github.com/$1/releases/tag/$RELEASE_TAG_PREFIX$VERSION

Thanks to everyone who participated in this release (both directly and indirectly) - your contributions are what keeps pushing PatternFly forward!

- The Red Hat UXD team
EEOOFF

  SUBJECT="The PatternFly $VERSION release is now available"
  if [ -n "$DRY_RUN" ]; then
    cat $TMP_DIR/$TMP_FILE
  else
    cat $TMP_DIR/$TMP_FILE | mail -s "The $2 v$VERSION Release is now available" "$3"
  fi
  rm -rf $TMP_DIR
}

# Fetch release notes from GitHub release
#
# $1: Repo slug
fetch_notes()
{
  echo "*** Fetch notes"

  RELEASE_NOTES=`curl -s https://api.github.com/repos/$1/releases/tags/$RELEASE_TAG_PREFIX$VERSION |
                 node -pe "JSON.parse(require('fs').readFileSync('/dev/stdin').toString()).body"`
  check $? "fetch notes failure"

  if [ "$RELEASE_NOTES" = "undefined" ]; then
    check 1 "Could not retrieve release notes.\nEnsure release has been published via GitHub."
  fi
}

usage()
{
cat <<- EEOOFF
    This script will send a release notice to the PatternFly, Angular PatternFly, and RCUE mailling lists.

    After publishing a release notes via GitHub, the script will pull the markup using GitHub APIs. The markup is then
    added to the body of the outgoing message.

    Note: You must configure your system to tell it where to send email. If you haven't done so, see:
    http://codana.me/2014/11/23/sending-gmail-from-os-x-yosemite-terminal

    sh [-x] $SCRIPT [-h|d] -a|p|r -v <version>

    Example: sh $SCRIPT -v 3.15.0 -p

    OPTIONS:
    h       Display this message (default)
    a       Angular PatternFly
    p       PatternFly
    r       RCUE
    v       The version number (e.g., 3.15.0)

    SPECIAL OPTIONS:
    d       Dry run (no email)

EEOOFF
}

# main()
{
  default

  if [ "$#" -eq 0 ]; then
    usage
    exit 1
  fi

  while getopts hadprv: c; do
    case $c in
      h) usage; exit 0;;
      a) EMAIL="$EMAIL_PTNFLY_ANGULAR";
         SUBJECT="Angular PatternFly";
         REPO_SLUG=$REPO_SLUG_PTNFLY_ANGULAR;;
      d) DRY_RUN=1;;
      p) EMAIL="$EMAIL_PTNFLY";
         SUBJECT="PatternFly";
         REPO_SLUG=$REPO_SLUG_PTNFLY;;
      r) EMAIL="$EMAIL_RCUE";
         SUBJECT="RCUE";
         REPO_SLUG=$REPO_SLUG_RCUE;;
      v) VERSION=$OPTARG;;
      \?) usage; exit 1;;
    esac
  done

  if [ -z "$VERSION" -o -z "$REPO_SLUG" ]; then
    usage
    exit 1
  fi

  fetch_notes $REPO_SLUG
  email $REPO_SLUG "$SUBJECT" "$EMAIL"
}
