#!/bin/bash

NETWORK=$1
export MEDIA_EOA=$2
APPLICATION_TIMESTAMP=$3
export MEDIA_METADATA_CID=$4
PROXY_ADDRESS=$5

if [ -z "${PROXY_ADDRESS}" ]; then
  stdout=$(yarn exec:newMedia:${NETWORK})
  if [ $? != 0 ]; then
    printf "${stdout}"
    exit 1;
  fi
  printf "${stdout}"
  PROXY_ADDRESS=$(printf "${stdout}" | tail -n 2 | head -1)
fi

MEDIA_EOA_LOWER=$(echo "${MEDIA_EOA}" | awk '{print tolower($0)}')
proxy_address_lower=$(echo "${PROXY_ADDRESS}" | awk '{print tolower($0)}')

if [ network == "polygon" ]; then
  storage=kaleido-backend-asset-prod
else
  storage=kaleido-backend-asset-v1dev
fi

aws s3 cp s3://${storage}/${MEDIA_EOA_LOWER}/application/${APPLICATION_TIMESTAMP}/media_header \
s3://${storage}/${proxy_address_lower}/
aws s3 cp s3://${storage}/${MEDIA_EOA_LOWER}/application/${APPLICATION_TIMESTAMP}/media_icon \
s3://${storage}/${proxy_address_lower}/

# for uploading to OpenSea
aws s3 cp s3://${storage}/${MEDIA_EOA_LOWER}/application/${APPLICATION_TIMESTAMP}/media_icon \
./${proxy_address}-media_icon


