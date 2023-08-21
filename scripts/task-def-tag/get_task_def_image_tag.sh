#!/bin/bash

set -x

eval "$(jq -r '@sh "task_def_name=\(.task_def_name) region=\(.region) profile=\(.profile)"')"

unset IFS
TASKDEF=$(aws --profile "$profile" --region "$region" ecs describe-task-definition --task-definition "$task_def_name" 2>/dev/null)
ret=$?
if [ $ret -eq 0 ]
then 
    IMAGE=$(echo $TASKDEF | jq -r '.taskDefinition.containerDefinitions[0].image')
    IMAGE_TAG=$(IFS=":" && read -a imagearr <<< "$IMAGE"; echo "${imagearr[1]}")
    echo "{\"image_tag\": \"$IMAGE_TAG\"}"
else 
    echo "{\"image_tag\":\"none\"}"
fi

