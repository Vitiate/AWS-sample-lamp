#!/bin/bash
ECSName=$(aws ssm get-parameter --name "/cloudformation/applications/$ENV/ecs-cluster/cluster/name" --output text --query Parameter.Value)
echo "Updating cluster $ECSName:"
aws ecs update-service --cluster $ECSName --service "$1" --force-new-deployment