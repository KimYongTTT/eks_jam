#!/bin/bash

export HOME_DIR="/opt/workspace"

echo '>> terraform init & apply step ...'
aws sts get-caller-identity
# eks_jam/environment
cd $HOME_DIR/eks_jam/environment
if [ -d $HOME_DIR/eks_jam/environment/.terraform ] ; then
    terraform apply -auto-approve
else
    terraform init -input=false && terraform apply -auto-approve
fi

# eks_jam/eks_blue
cd $HOME_DIR/eks_jam/eks_blue
if [ -d $HOME_DIR/eks_jam/eks-blue/.terraform ] ; then
    terraform apply -auto-approve
else
    terraform init -input=false && terraform apply -auto-approve
fi

alias k='kubectl'
export AWS_REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')

echo ' '
echo '>> running terraform complete!!'