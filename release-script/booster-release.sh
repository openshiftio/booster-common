#!/bin/bash
set -e

RED='\033[0;31m'
NC='\033[0m' # No Color
YELLOW='\033[0;33m'
BLUE='\033[0;34m'

if ((`git status -sb | wc -l` != 1)); then
    echo -e "${RED} You have uncommitted changes, please check (and stash) these changes before running this script ${NC}"
    exit 1
fi

CURRENT_VERSION=`mvn help:evaluate -Dexpression=project.version | grep -e '^[^\[]'`
echo -e "${BLUE}CURRENT VERSION: ${YELLOW} ${CURRENT_VERSION} ${NC}"

if [[ "$CURRENT_VERSION" == *-SNAPSHOT ]]
then
    L=${#CURRENT_VERSION}
    PART=(${CURRENT_VERSION//-/ })
    NEW_VERSION=${PART[0]}
    QUALIFIER=${PART[1]}
    if [[ "$QUALIFIER" != SNAPSHOT ]]
    then
        QUALIFIER="${QUALIFIER}-SNAPSHOT"
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

NEXT_VERSION="$(($NEW_VERSION +1))-${QUALIFIER}"
echo -e "${BLUE}Updating project version to: ${YELLOW}${NEXT_VERSION}${NC}"
mvn versions:set -DnewVersion=${NEXT_VERSION} > bump-version-dev.log

echo -e "${BLUE}Committing changes${NC}"
git commit -am "Bumping version to ${NEXT_VERSION}"

echo -e "${BLUE}Pushing changes${NC}"
git push origin master --tags

echo -e "DONE !"
rm *.log pom.xml.versionsBackup