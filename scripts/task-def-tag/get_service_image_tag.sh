#!/bin/bash

set -x

eval "$(jq -r '@sh "task_def_name=\(.task_def) cluster=\(.cluster) image_wanted=\(.image) region=\(.region) desired_tag=\(.desired_tag) service=\(.service_name) profile=\(.aws_profile) container_name=\(.container_name)"')"

if [[ $region == us-gov-* ]]; then
  export main_region=us-gov-west-1
  export ecr_endpoint_type=ecr-fips
else
  export main_region=us-east-1
  export ecr_endpoint_type=ecr
fi

if [ -z "$desired_tag" -o "x$desired_tag" = "xcurrent" ]; then
  service_deets=$(aws ecs describe-services --profile "$profile" --services "$service" --region "$region" --cluster $cluster)
  task_def_name=$(jq -r '.services[0].taskDefinition' <<< "$service_deets")
  task_def_deets=$(aws ecs describe-task-definition --profile "$profile" --region "$region" --task-definition "$task_def_name")

  if [ -n "$task_def_deets" ]; then
    if [ -z "$container_name" -o "x$container_name" = "xnull" ]; then
      image=$(jq -r ".taskDefinition.containerDefinitions[0] | .image" <<< "$task_def_deets")
    else
      image=$(jq -r --arg container_name "$container_name" '.taskDefinition.containerDefinitions[] | select(.name == $container_name) | .image' <<< "$task_def_deets")
    fi
    image_tag=${image##*:}
    image_name=${image##*.dkr.${ecr_endpoint_type}.${main_region}.amazonaws.com/sailpoint/}
    image_name=${image_name%:*}
  fi
else
  image_name="$image_wanted"
  image_tag="$desired_tag"
fi

if [ -z "$image_tag" ]; then
  echo "Could not determine proper tag. If this service doesn't exist currently then you will need to set the container tag explicitly" 1>&2
  exit 1
fi

cat <<EOF
{
  "image_name": "$image_name",
  "image_tag": "$image_tag"
}
EOF
