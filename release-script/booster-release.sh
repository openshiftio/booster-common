#!/bin/bash
set -e

RED='\033[0;31m'
NC='\033[0m' # No Color
YELLOW='\033[0;33m'
BLUE='\033[0;34m'

CURRENT_VERSION=`mvn help:evaluate -Dexpression=project.version | grep -e '^[^\[]'`
echo -e "${BLUE}CURRENT VERSION: ${YELLOW} ${CURRENT_VERSION} ${NC}"

if [[ "$CURRENT_VERSION" == *-SNAPSHOT ]]
then
    L=${#CURRENT_VERSION}
    IDX=$(($L - 9))
    NEW_VERSION=${CURRENT_VERSION:0:${IDX}}
else
    echo -e "${RED} The current version (${CURRENT_VERSION}) is not a SNAPSHOT ${NC}"
    exit 1
fi

echo -e "${BLUE}Updating project version to: ${YELLOW} ${NEW_VERSION} ${NC}"
mvn versions:set -DnewVersion=${NEW_VERSION} > bump-version.log

echo -e "${BLUE}Issuing a verification build${NC}"
mvn clean verify > verification.log

echo -e "${BLUE}Committing changes${NC}"
git add pom.xml
git commit -m "Bumping version to ${NEW_VERSION}"

TAG="v${NEW_VERSION}"
echo -e "${BLUE}Creating the tag ${YELLOW}${TAG}${NC}"
git tag -a ${TAG} -m "Releasing ${TAG}"

NEXT_VERSION="$(($NEW_VERSION +1))-SNAPSHOT"
echo -e "${BLUE}Updating project version to: ${YELLOW}${NEXT_VERSION}${NC}"
mvn versions:set -DnewVersion=${NEXT_VERSION} > bump-version-dev.log

echo -e "${BLUE}Committing changes${NC}"
git add pom.xml
git commit -m "Bumping version to ${NEXT_VERSION}"

echo -e "${BLUE}Pushing changes${NC}"
git push origin master --tags

echo -e "DONE !"
# Just some cleanup
rm *.log pom.xml.versionsBackup