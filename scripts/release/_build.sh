#!/bin/sh

default()
{
  SCRIPT=`basename $0`
  SCRIPT_DIR=`dirname $0`
  SCRIPT_DIR=`cd $SCRIPT_DIR; pwd`

  . $SCRIPT_DIR/../_env.sh
  . $SCRIPT_DIR/../_common.sh
  . $SCRIPT_DIR/_common.sh

  BUILD_DIR=$TRAVIS_BUILD_DIR
}

# Add tag to kick off Angular Patternfly version bump
#
add_apf_tag()
{
  echo "*** Adding Angular Patternfly tag"
  cd $BUILD_DIR

  # Add tag to kick off version bump
  git fetch apf master:master-apf # <remote-branch>:<local-branch>
  git checkout master-apf
  git tag $BUMP_TAG_PREFIX$VERSION -f
  git push apf tag $BUMP_TAG_PREFIX$VERSION
  check $? "add apf tag failure"
}

# Add tag to kick off Patternfly version bump
#
add_pf_tag()
{
  echo "*** Adding Patternfly tag"
  cd $BUILD_DIR

  # Add tag to kick off version bump
  git fetch pf master:master-pf # <remote-branch>:<local-branch>
  git checkout master-pf
  git tag $BUMP_TAG_PREFIX$VERSION -f
  git push pf tag $BUMP_TAG_PREFIX$VERSION
  check $? "add pf tag failure"
}

# Add tag to kick off Patternfly Org version bump
#
add_pfo_tag()
{
  echo "*** Adding Patternfly Org tag"
  cd $BUILD_DIR

  # Add tag to kick off version bump
  git fetch pfo master:master-pfo # <remote-branch>:<local-branch>
  git checkout master-pfo
  git tag $BUMP_TAG_PREFIX$VERSION -f
  git push pfo tag $BUMP_TAG_PREFIX$VERSION
  check $? "add pfo tag failure"
}

# Add tag to kick off Patternfly Web Components version bump
#
add_pfwc_tag()
{
  echo "*** Adding Patternfly Org tag"
  cd $BUILD_DIR

  # Add tag to kick off version bump
  git fetch pfwc master:master-pfwc # <remote-branch>:<local-branch>
  git checkout master-pfwc
  git tag $BUMP_TAG_PREFIX$VERSION -f
  git push pfwc tag $BUMP_TAG_PREFIX$VERSION
  check $? "add pfwc tag failure"
}

# Add tag to kick off RCUE version bump
#
add_rcue_tag()
{
  echo "*** Adding RCUE tag"
  cd $BUILD_DIR

  # Add tag to kick off version bump
  git fetch rcue master:master-rcue # <remote-branch>:<local-branch>
  git checkout master-rcue
  git tag $BUMP_TAG_PREFIX$VERSION -f
  git push rcue tag $BUMP_TAG_PREFIX$VERSION
  check $? "add rcue tag failure"
}

# Add release tag
#
add_release_tag()
{
  echo "*** Adding release tag"
  cd $BUILD_DIR

  # Add release tag
  git tag $RELEASE_TAG_PREFIX$VERSION
  check $? "add tag failure"
  git push upstream tag $RELEASE_TAG_PREFIX$VERSION
  check $? "git push tag failure"
}

# Delete tag used to kick off version bump
#
delete_bump_tag()
{
  echo "*** Deleting bump tag"
  cd $BUILD_DIR

  # Remove bump tag
  git tag -d $BUMP_TAG_PREFIX$VERSION
  git push upstream :refs/tags/$BUMP_TAG_PREFIX$VERSION
  check $? "delete tag failure"
}

# Check prerequisites before continuing
#
prereqs()
{
  echo "This build is running against $TRAVIS_REPO_SLUG"

  if [ -n "$TRAVIS_TAG" ]; then
    echo "This build is running against $TRAVIS_TAG"

    # Get version from tag
    case "$TRAVIS_TAG" in
      $BUMP_TAG_PREFIX* ) VERSION=`echo "$TRAVIS_TAG" | cut -c $BUMP_TAG_PREFIX_COUNT-`;;
      *) check 1 "$TRAVIS_TAG is not a recognized format. Do not release!";;
    esac
  fi

  delete_bump_tag # Wait until we have the version

  # Ensure release runs for main repo only
  if [ "$TRAVIS_REPO_SLUG" != "$REPO_SLUG" ]; then
    check 1 echo "Release must be performed on $REPO_SLUG only!"
  fi

  git tag | grep "^$RELEASE_TAG_PREFIX$VERSION"
  if [ $? -eq 0 ]; then
    check 1 "Tag $RELEASE_TAG_PREFIX$VERSION exists. Do not release!"
  fi
}

usage()
{
cat <<- EEOOFF

    This script will build, publish, and release the repo.

    If a custom Git tag has been created to publish a release, the Git tag will be deleted first. Then, the appropriate
    scripts will be called to bump version numbers and publish the repo. Finally, a custom tag will be created to kick
    off the release for the Angular Patternfly, Patternfly Org and RCUE repos.

    Note: Intended for use with Travis only.

    AUTH_TOKEN must be set via Travis CI.

    sh [-x] $SCRIPT [-h] -a|e|o|p|r|w

    Example: sh $SCRIPT -p

    OPTIONS:
    h       Display this message (default)
    a       Angular PatternFly
    e       Patternfly Eng Release
    o       PatternFly Org
    p       PatternFly
    r       PatternFly RCUE
    w       Patternfly Web Components

EEOOFF
}

# main()
{
  default

  if [ "$#" -eq 0 ]; then
    usage
    exit 1
  fi

  while getopts haeoprw c; do
    case $c in
      h) usage; exit 0;;
      a) PTNFLY_ANGULAR=1;
         REPO_SLUG=$REPO_SLUG_PTNFLY_ANGULAR;
         SWITCH=a;;
      e) PTNFLY_ENG_RELEASE=1;
         REPO_SLUG=$REPO_SLUG_PTNFLY_ENG_RELEASE;
         SWITCH=e;;
      o) PTNFLY_ORG=1;
         REPO_SLUG=$REPO_SLUG_PTNFLY_ORG;
         SWITCH=o;;
      p) PTNFLY=1;
         REPO_SLUG=$REPO_SLUG_PTNFLY;
         SWITCH=p;;
      r) PTNFLY_RCUE=1;
         REPO_SLUG=$REPO_SLUG_RCUE;
         SWITCH=r;;
      w) PTNFLY_WEB_COMPS=1;
         SWITCH=w;;
      \?) usage; exit 1;;
    esac
  done

  prereqs # Check for existing tag before fetching remotes
  git_setup

  # Bump version numbers, build, and test
  sh -x $SCRIPT_DIR/release.sh -s -v $VERSION -$SWITCH
  check $? "bump version failure"

  # Push version bump and generated files to master and master-dist
  if [ -n "$PTNFLY" -o -n "$PTNFLY_ANGULAR" ]; then
    sh -x $SCRIPT_DIR/_publish.sh -m -d
  else
    sh -x $SCRIPT_DIR/_publish.sh -m
  fi
  check $? "Publish failure"

  # Skip npm publish
  if [ -z "$SKIP_NPM_PUBLISH" ]; then
    if [ -n "$PTNFLY" -o -n "$PTNFLY_ANGULAR" -o -n "$PTNFLY_ENG_RELEASE" ]; then
      sh -x $SCRIPT_DIR/publish-npm.sh -$SWITCH
      check $? "npm publish failure"
    fi
  fi

  add_release_tag # Add release tag

  if [ -n "$PTNFLY" ]; then
    add_apf_tag # Kick off apf version bump
    add_rcue_tag # Kick off rcue version bump
  elif [ -n "$PTNFLY_ANGULAR" ]; then
    add_pfo_tag # Kick off Patternfly Org version bump
  elif [ -n "$PTNFLY_ENG_RELEASE" ]; then
    add_pf_tag # Kick off Patternfly version bump
  elif [ -n "$PTNFLY_WEB_COMPS" ]; then
    add_pfwc_tag # Kick off Patternfly Web Components version bump
  fi
}
