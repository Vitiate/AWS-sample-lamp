# AU CloudFormation Orchestration

## Stack Operations

The repo is organized into components and parameters.

```bash
.
├── Makefile
├── README.md
├── docker-image
│   └── See README
├── components
│   ├── ecs-cluster.yaml
│   ├── load-balancer.yaml
│   ├── networking.yaml
│   └── security-groups.yaml
└── environments
    ├── dev
    │   ├── ecs-cluster.json
    │   ├── load-balancer.json
    │   ├── networking.json
    │   └── security-groups.json
    └── prod
        ├── ecs-cluster.json
        ├── load-balancer.json
        ├── networking.json
        └── security-groups.json

    # etc
```

## Local Stack Development

You must have the AWS CLI installed and properly configured. A configuration profile matching the environement name will need to be created. For example:
~./aws/config:
```bash
[profile sandbox]
role_arn = arn:aws:iam::**********:role/****** # This is for users that are switching roles
source_profile = default
mfa_serial = GAK********* # if you do not have a MFA do not worry about this
region = us-east-1
```
~./aws/
```
[default]
aws_access_key_id = AKIA************* # an access key from your aws IAM user account
aws_secret_access_key = ************************ # secret key from your IAM user account
```

## Installing cfn-lint

You should be linting your changes before pushing them to the repo. The push will trigger a lint on the repo, linting locally will save you some commits.

Ensure you have python and pip installed. If you are using RHEL you will need to look at how to setup a environment to install into. then:
```bash
pip install cfn-lint
```

After this is complete cd to the root of this repo and run:
```
cfn-lint -i="W1020,W2001" components/*.yaml
```

You can also configure cfn-lint to run as part of your IDE/Editor. I will not go into this here.

## Deploying Changes

__DO NOT PUSH CHANGES TO PRODUCTION ENVIRONMENTS, THIS BREAKS THE CI/CD PROCESS__

To push changes to an environment locally you should setup a file called local.sh in the root directory of this repo (this file is in the ignore list):
```bash
export PROJECT=applications
export ENV=sandbox
export PROFILE=sandbox
```

To update the moodle34-base stack, this will also create a new stack if one does not exist:

```bash
source ./local.sh
COMPONENT=moodle34-base make update-stack
```

This will result in a CloudFormation stack named `applications-moodle34-base-dev`.

## make_scripts
This folder contains 3 different scripts that when executed perform different options.
The ```make_image.sh``` will build a new docker image and push it to the AWS ECR associated with this application.
The ```update_service.sh``` will force the AWS ECS cluster to deploy a new docker image.
The ```update_stack.sh``` is used for general cloudformation deployment operations.

## Parameter Store

Certain values will be written into Parameter Store using the following scheme:

```
/cloudformation/<application>/<environment>/<component>/<resource_name>/<attribute>
```

For instance: `/cloudformation/applications/dev/networking/private-subnets/ids` will resolve to a comma-separated list of the private subnets in the VPC template.

This is usable in other templates as a `AWS::SSM::Parameter::Value`, for example:

```yaml
Parameters:
  SsmLookupSubnetIds:
    Description: Choose which subnets this ECS cluster should be deployed to
    Type: AWS::SSM::Parameter::Value<List<AWS::EC2::Subnet::Id>>
    Default: /cloudformation/applications/dev/networking/private-subnets/ids
```

## Deploying Infrastructure

The following will deploy an ECS cluster underpinned by an ASG, and an ALB.

```
# Set necessary environments variables.
export PROFILE=profile-name   # AWS Profile from ~/.aws to target.
export PROJECT=applications
export ENV=dev

# First deploy the networking stack.
COMPONENT=networking      make update-stack
COMPONENT=security-groups make update-stack

# Deploy the cluster and associated components.
COMPONENT=ecs-cluster    make update-stack
COMPONENT=load-balancer  make update-stack
COMPONENT=lifecycle-hook make update-stack
COMPONENT=ecr            make update-stack
````
