#!/usr/bin/bash

## Configure ECR Helper if AWS credentials are available ##
if [[ -z "${ARGOCD_ENV_REGION}" ]]; then
    if [[ -z "${AWS_REGION}" ]]; then
        echo "INFO: Could not find AWS region in environment."
    else
        REGION=${AWS_REGION}
    fi
else
    REGION=${ARGOCD_ENV_REGION}
fi

if [[ -z "${ARGOCD_ENV_ACCOUNT_ID}" ]]; then
    if [[ -z "${AWS_ROLE_ARN}" ]]; then
        echo "INFO: Could not find AWS account ID in environment."
    else
        ACCOUNT_ID=$(echo "${AWS_ROLE_ARN}" | cut -d':' -f5)
    fi
else
    ACCOUNT_ID=${ARGOCD_ENV_ACCOUNT_ID}
fi

if [[ -n "${REGION}" || -n "${ACCOUNT_ID}" ]]; then
    echo "INFO: Replacing ACCOUNT_ID and REGION in /home/argocd/.docker/config.json"
    sed -i.bak 's/ACCOUNT_ID/'"$ACCOUNT_ID"'/g; s/REGION/'"$REGION"'/g' /home/argocd/.docker/config.json
fi
