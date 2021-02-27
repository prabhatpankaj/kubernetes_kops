#!/bin/bash

export AWS_DEFAULT_REGION=us-east-1

export AWS_ACCESS_KEY_ID=$(cat kops-creds | \
    jq -r '.AccessKey.AccessKeyId')

export AWS_SECRET_ACCESS_KEY=$(cat kops-creds | \
    jq -r '.AccessKey.SecretAccessKey')

export nodecount=1

export ZONES=$(aws ec2 describe-availability-zones \
    --region $AWS_DEFAULT_REGION | jq -r \
    '.AvailabilityZones[].ZoneName' | head -$nodecount | tr '\n' ',' | tr -d ' ')

ZONES=${ZONES%?}

echo $ZONES

# Must change: Your domain name that is hosted in AWS Route 53
export DOMAIN_NAME="prabhatpankaj.me"

# Friendly name to use as an alias for your cluster
export CLUSTER_ALIAS="k8slab"

# Leave as-is: Full DNS name of you cluster
export CLUSTER_FULL_NAME="${CLUSTER_ALIAS}.${DOMAIN_NAME}"

# Bucket name for state store of kops and Terraform.
export BUCKET_NAME=kopsprabhat

export KOPS_STATE_STORE=s3://$BUCKET_NAME
