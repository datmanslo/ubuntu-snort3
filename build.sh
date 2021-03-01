#!/bin/sh -eu
REQUIRED="docker curl"

echo "Checking prerequisites: Docker, Curl\n"

# Check Requirements
for req in $REQUIRED
do
    echo "Verifying ${req}"
    if [ -x "$(command -v ${req})" ]; then
        echo "${req} is installed. Moving on...\n"
    else
        echo "${req} is required and does not appear to be installed."
        echo "Exiting...\n"
        exit
    fi
done

# Check and set current OpenApp ID version from https://snort.org
ODP_URL=https://snort.org/downloads/openappid/$(curl --silent https://snort.org/downloads | egrep "<a href=\"\/downloads\/openappid\/[0-9]{5,}\">snort-openappid\.tar\.gz<\/a>" | awk '{gsub(/[^0-9]/,"")}1')

# Build an image for each stage
IMAGE_NAME=datmanslo/snort3

echo "Starting the buildtime stage...\n"
cat Dockerfile | \
  docker build \
    --build-arg ODP_URL=${ODP_URL} \
    --target builder \
    -t ${IMAGE_NAME}-build -

echo "Creating the runtime image...\n"
cat Dockerfile | \
  docker build \
    --build-arg ODP_URL=${ODP_URL} \
    -t ${IMAGE_NAME} -
