#!/bin/bash

set -e

NS=$1
USERNAME=$2

read -s -p "Enter Password  : " PASSWORD

echo " "

echo "Creating secret with github credentials for user $USERNAME"
cat $(pwd)/git-secret.yaml | USERNAME=$USERNAME \
  PASSWORD=${PASSWORD} envsubst | oc apply -f - -n $NS 

echo "Linking pipeline sa in namespace $NS with your github crendentials"
oc patch serviceaccount pipeline -p \
  '{"secrets": [{"name": "github-credentials"}]}' \
  -n $NS 
