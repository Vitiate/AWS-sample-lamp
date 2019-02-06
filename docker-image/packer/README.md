# docker-image Packer Build

## Building a docker image
These folders contain everything needed to create a docker image using packer and ansible for local configuration.


```bash
.
├── packer
│   └── aumoodle-template.json
├── ansible-local
│   ├── moodle_ami.yaml
│   └── templates
│       └── configfile.php.j2
└── README.md

```

## Local packer Development

You must have packer installed locally, please see https://www.packer.io/intro/getting-started/install.html

```bash
# Store the ecr location in a file so we can pull it out in the next step
aws ssm get-parameter --name "/cloudformation/applications/dev/ecr/sample-app" --output text --query Parameter.Value > ~/ecrRegistry
# Build the image, 
ECRURL=$(cat ~/ecrRegistry) && ~/packer/packer build -var "docker-repo=$ECRURL" -var "playbook_dir=docker-image/ansible-local" -var "build_version=$CI_MERGE_REQUEST_ID" -var "ssmdbparam=/cloudformation/applications/dev/sample-app-rds/secret/name" docker-image/packer/sample-lamp.json
```

## Debugging

To debug your packer build simply the following. This will start the packer process and will output both the key.pem and the ip address so that you can connect to the builder ec2 instance for troubleshooting. It is also recommended to perform syntax tests on both the packer and ansible-local scripts.

# AWS Config

You must have the AWS CLI installed and properly configured. A configuration profile matching the environement name will need to be created. For example:
~./aws/config:
```bash
[profile sandbox]
role_arn = arn:aws:iam::**********:role/****** # This is for users that are switching roles
source_profile = default
mfa_serial = GAK********* # if you do not have a MFA do not worry about this
region = us-east-1
```

# Pull a docker image to test locally

## Get the login string for the repository
```bash
aws --profile dev ecr get-login --region region --no-include-email
```

## Copy and paste the docker login command, and run it
```bash
docker login -u AWS -p $$KEY$$ https://564063436012.dkr.ecr.us-east-1.amazonaws.com

WARNING! Using --password via the CLI is insecure. Use --password-stdin.
WARNING! Your password will be stored unencrypted in /home/jtirrell/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded

```

## Pull the image
```bash
docker pull 564063436012.dkr.ecr.us-east-1.amazonaws.com/applications/dev/ecr/sample-app:latest
```