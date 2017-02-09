# patternfly-eng-release
A set of release engineering scripts for PatternFly, Angular PatternFly, PatternFly Org, and RCUE

## Builds

For normal builds, Travis runs the build/_build.sh script. This script determines if we're building a pull request, simple tag, merge, or release. If a commit is tagged for release, the build/release/_build.sh script takes over. Otherwise, the scripts run npm/bower install, build, npm test, nsp shrinkwrap audit, etc. If the build is ssuccessful, generated build files are pushed to master-dist if applicable -- tags and pull requests are not pushed to master-dist.

## Automated Release Process

At periodic intervals PatternFly, and all repos which utilize PF, must be versioned. Below is a summary of all the steps involved. For more information on each repo, please see [PatternFly Documentation](https://depot-uxd.itos.redhat.com/uxd-team/uxd-dev-team/#docs).

Where applicable to each repo, the scripts may clone a new GitHub repo, bump the npm/bower version and website home page version numbers. The scripts will also clean the npm/bower cache, run npm install, bower install, grunt build, grunt ngdocs:publish, npm shrinkwrap, npm publish, npm test, nsp shrinkwrap audit, and will verify npm/bower installs.

The automated release build begins with the build/release/release-all.sh script. This script will push a custom release tag to the repo's master branch, which triggers Travis to run the build/release/build.sh script. Version bump changes are pushed back to the master branch. The version bump and generated build changes are pushed to master-dist and tagged (e.g., v3.15.0).

Release builds are chained together by pushing a new custom release tag to the next repo. For example, if the PatternFly RE release is successful, PatternFly is built next. If the PatternFly release is successful, RCUE and Angular PatternFly are built simultaneously. If Angular is successful, PatternFly Org is released as well.

Should a release build fail at any point, it can be fixed and restarted. For example, If Angular PatternFly fails, it can be restarted and the PatternFly Org release will follow. We don't necessarily need to bump the npm version number again or rebuild Patternfy. The npm publish is one of the last steps in the build.

Of course, we still have the ability to run the release manually using the build/release/release.sh script. In fact, the release build uses this script itself.

### build/release/release-all.sh

This script is used to automate and chain releases together. For example, when the PatternFly RE release is complete, PatternFly is built next. When the PatternFly release is complete, the release processes for Angular PatternFly and RCUE are kicked off simultaneously. When the Angular PatternFly release is complete, PatternFly Org shall be released as well.

Although there is no PR to deal with here, creating release notes is still a task which must be performed manually via GitHub.

Builds can only be stopped via the Travis CI.

1. Choose version using [semantic versioning](https://docs.npmjs.com/getting-started/semantic-versioning) ([details](https://github.com/patternfly/patternfly/blob/master/README.md#release))
2. Bump the version number, build, etc., starting with the patternfly-eng-release repo
 - Run sh ./build/release/release-all.sh -v 3.15.0 -e
3. Release Notes Published (via GitHub)
 - Tag “master-dist” branch commit with updated version
4. Community email sent to announce release

### build/release/notify.sh

This script will send community email to the PatternFly and Angular PatternFly mailling lists.

After publishing a release notes via GitHub, this script will pull markup using GitHub APIs. The release note markup is then added to the body of the outgoing message.

1. Send community email to patternfly@redhat.com
 - Run sh ./build/release/notify.sh -v 3.15.0 -p
2. Send community email to patternfly-angular@redhat.com
 - Run sh ./build/release/notify.sh -v 3.15.0 -a

### Environment Variables

It is expected that the following environment variables are set via Travis CI.

- AUTH_TOKEN: A personal access token, created via GitHub, used for pushing changes.
- NPM_USER: A user with permission to npm publish.
- NPM_PWD: The password of the user with permission to npm publish.

## Next Release

For PF 'next' releases (e.g., PF4 aplha, beta, etc.), the following variables may be overridden.

- NEXT_BRANCH=branch-4.0-dev
- NEXT_DIST_BRANCH=branch-4.0-dev-dist

1. Bump the version number, build, etc., starting with the patternfly-eng-release repo
 - Run sh ./build/release/release-all.sh -v 4.0.0-alpha.1 -e -n

Note: Environment variables must be committed for the automated release, but may be overridden locally for manual releases.

## Testing

When testing, run the scripts first from a forked repo to avoid accidentally merging and publishing releases.

1. Run the `whoami` command to view your username.
 - Confirm this user name matches your forked repo(s) (e.g., github.com/`whoami`/patternfly.git).
2. Bump the version number, build, etc., starting with the patternfly-eng-release repo
 - Run sh ./build/release/release-all.sh -v 3.15.0 -e -f

If your local user name is not a match, set the following environment variables locally.

- REPO_FORK=1: A flag indicating script are running against a fork instead of main repo(s).
- REPO_OWNER: The repo owner (e.g., github.com/`owner_name`/`repo_name`.git)

Alternatively, the following variables may be overridden to test forked repos and skip npm and webjar publish.

- REPO_SLUG_PTNFLY=`owner_name`/patternfly
- REPO_SLUG_PTNFLY_ANGULAR=`owner_name`/angular-patternfly
- REPO_SLUG_PTNFLY_ORG=`owner_name`/patternfly-org
- REPO_SLUG_PTNFLY_ENG_RELEASE=`owner_name`/patternfly-eng-release
- REPO_SLUG_RCUE=`owner_name`/rcue
- SKIP_NPM_PUBLISH=1
- SKIP_WEBJAR_PUBLISH=1

Note: Testing from a fork may require both master and master-dist branches to simulate npm and bower installs.

## Verify

When verifying changes, please ensure:

- Tags and pull requests are built without pushing changes
- Merges are built with generated files pushed to master-dist
- Release tags are built with version bump pushed to master
- Release tags are built with version bump and generated files pushed to master-dist
- Scripts should fail if a release tag already exists in one or more repos
- Scripts (e.g., release.sh) should continue to run via the command line

## Manual Release Process

Although many release steps have been automated here, this is more of a manual release process. Releases are not chained together, so creating a PR, release notes, and community email are still tasks which must be performed manually.

These scripts are useful when debugging build issues or publishing individual releases.

Note: The release-all.sh script will run these scripts automatically.

### build/release/release.sh

This script will bump version numbers, build, shrinkwrap, test, install, push to GitHub, and publish to npm. These changes are committed to a branch that must be merged via a PR on GitHub.

1. Choose version using [semantic versioning](https://docs.npmjs.com/getting-started/semantic-versioning) ([details](https://github.com/patternfly/patternfly/blob/master/README.md#release))
2. Bump the version number, build, etc.
 - Run sh ./build/release/release.sh -v 3.15.0 -g -a|e|o|p|r|w
3. Review test pages, verify latest changes
 - cd /tmp/patternfly-releases/patternfly
 - Run grunt server
4. PR reviewed & merged (no dist files should be checked in)
5. NPM Publish
 - Create an NPM account and become a collaborator for https://www.npmjs.com/package/patternfly
 - Run sh ./build/release/publish-npm.sh -a|e|p
6. Release Notes Published (via GitHub)
 - Tag “master-dist” branch commit with updated version
7. Community email sent to announce release

### build/release/publish-npm.sh
 
This script will npm publish from the latest repo clone or Travis build.
 
1. Create an NPM account and become a collaborator for https://www.npmjs.com/package/patternfly
 - Run sh ./build/release/publish-npm.sh -a|e|p
