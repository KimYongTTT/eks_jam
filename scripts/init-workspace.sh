#!/bin/bash

sudo yum update
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo apt install jq

# Install AWS CLI v2
rm $HOME/.local/bin/aws
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install --update
rm awscliv2.zip

# Configure Cloud9 credentials
aws cloud9 update-environment  --environment-id $C9_PID --managed-credentials-action DISABLE
rm -vf ${HOME}/.aws/credentials

# Install kubectl & set kubectl as executable, move to path, populate kubectl bash-completion
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "source <(kubectl completion bash | sed 's/kubectl/k/g')" >> ~/.bashrc

# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv -v /tmp/eksctl /usr/local/bin

# Install Terraform
sudo yum -y install terraform

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install ArgoCD CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# Install k9s
K9S_VERSION=v0.27.4
curl -sL https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz | sudo tar xfz - -C /usr/local/bin k9s

# Generate SSH key pair, create IAM user, attach policy, upload SSH public key
IAM_USER="jam-codecommit-user"
ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
aws iam create-user --user-name $IAM_USER
aws iam attach-user-policy --user-name $IAM_USER --policy-arn arn:aws:iam::aws:policy/AWSCodeCommitPowerUser
aws iam upload-ssh-public-key --user-name $IAM_USER --ssh-public-key-body file://~/.ssh/id_rsa.pub
SSH_KEY_ID=$(aws iam list-ssh-public-keys --user-name $IAM_USER --query 'SSHPublicKeys[?Status==`Active`].SSHPublicKeyId' --output text)
cat <<EOF > ~/.ssh/config
Host git-codecommit.*.amazonaws.com
    User $SSH_KEY_ID
    IdentityFile ~/.ssh/id_rsa
EOF
chmod 600 ~/.ssh/config

# export JAM_LABS_USER_ARN & AWS_REGION
rolearn=$(aws iam get-role --role-name $(aws cloud9 describe-environment-memberships --environment-id=$C9_PID | jq -r '.memberships[].userArn' | awk -F/ '{print $(NF-1)}') --query Role.Arn --output text)
export JAM_LABS_USER_ARN=$rolearn
export AWS_REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')

alias k='kubectl'