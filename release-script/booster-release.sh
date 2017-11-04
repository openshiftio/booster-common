#!/bin/bash
set -e

RED='\033[0;31m'
NC='\033[0m' # No Color
YELLOW='\033[0;33m'
BLUE='\033[0;34m'

if ((`git status -sb | wc -l` != 1)); then
    echo -e "${RED}You have uncommitted changes, please check (and stash) these changes before running this script${NC}"
    exit 1
fi

# check that we have proper git information to automatically commit and push
# git status -sb has the following format: ## master...upstream/master when tracking a remote branch
GIT_STATUS=`git status -sb`
GIT_STATUS_PARTS=${GIT_STATUS//##/}
GIT_STATUS_PARTS=(${GIT_STATUS_PARTS//.../ })
GIT_BRANCH=${GIT_STATUS_PARTS[0]}
GIT_REMOTE=(${GIT_STATUS_PARTS[1]//\// })
if [[ "$GIT_REMOTE" == ?? ]]; then
    echo -e "${RED}Current ${YELLOW}${GIT_BRANCH}${RED} branch is not tracking a remote. Please make sure your branch is tracking a remote (git branch -u <remote name>/<remote branch name>)!${NC}"
    exit 1
fi
GIT_REMOTE=${GIT_REMOTE[0]}
GIT_BRANCH=${GIT_REMOTE[1]}

CURRENT_VERSION=`mvn help:evaluate -Dexpression=project.version | grep -e '^[^\[]'`
echo -e "${BLUE}CURRENT VERSION: ${YELLOW} ${CURRENT_VERSION} ${NC}"

if [[ "$CURRENT_VERSION" == *-SNAPSHOT ]]
then
    L=${#CURRENT_VERSION}
    PART=(${CURRENT_VERSION//-/ })
    NEW_VERSION_INT=${PART[0]}
    QUALIFIER=${PART[1]}
    SNAPSHOT=${PART[2]}
    if [[ "$SNAPSHOT" == SNAPSHOT ]]
    then
        NEW_VERSION="${NEW_VERSION_INT}-${QUALIFIER}"
        NEXT_VERSION="$(($NEW_VERSION_INT +1))-${QUALIFIER}-SNAPSHOT"
    else
        NEW_VERSION="${NEW_VERSION_INT}"
        NEXT_VERSION="$(($NEW_VERSION_INT +1))-SNAPSHOT"
    fi
else
    echo -e "${RED} The current version (${CURRENT_VERSION}) is not a SNAPSHOT ${NC}"
    exit 1
fi

echo -e "${BLUE}Updating project version to: ${YELLOW} ${NEW_VERSION} ${NC}"
mvn versions:set -DnewVersion=${NEW_VERSION} > bump-version.log

echo -e "${BLUE}Issuing a verification build${NC}"
mvn clean verify > verification.log

echo -e "${BLUE}Committing changes${NC}"
git commit -am "Bumping version to ${NEW_VERSION}"

TAG="v${NEW_VERSION}"
echo -e "${BLUE}Creating the tag ${YELLOW}${TAG}${NC}"
git tag -a ${TAG} -m "Releasing ${TAG}"

echo -e "${BLUE}Updating project version to: ${YELLOW}${NEXT_VERSION}${NC}"
mvn versions:set -DnewVersion=${NEXT_VERSION} > bump-version-dev.log

echo -e "${BLUE}Committing changes${NC}"
git commit -am "Bumping version to ${NEXT_VERSION}"

echo -e "${BLUE}Pushing changes to ${YELLOW}${GIT_BRANCH}${BLUE} branch of ${YELLOW}${GIT_REMOTE}${BLUE} remote${NC}"
git push $GIT_REMOTE $GIT_BRANCH --tags

echo -e "DONE !"
rm *.log
find . -name "*.versionsBackup" -exec rm -f {} \;