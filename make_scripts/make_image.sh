if [ ! -d "$HOME/packer" ]; then 
	mkdir ~/packer 
	pushd ~/packer
	wget https://releases.hashicorp.com/packer/1.3.4/packer_1.3.4_linux_amd64.zip
	unzip ./packer_1.3.4_linux_amd64.zip
	popd
fi

# Store the ecr location so we can pull it out in the next step
ECRURL=$(aws ssm get-parameter --name "/cloudformation/applications/$ENV/ecr/$1" --output text --query Parameter.Value)
# Build the image
~/packer/packer build -var "docker-repo=$ECRURL" -var "playbook_dir=docker-image/ansible-local" -var "build_version=$CI_COMMIT_SHORT_SHA" -var "ssmdbparam=/cloudformation/applications/$ENV/$1-rds" docker-image/packer/$1.json
