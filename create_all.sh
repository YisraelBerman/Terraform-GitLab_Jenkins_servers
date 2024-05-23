#!/bin/bash  

terraform init
echo " "
echo " "
echo "Creating VPC"

terraform apply -auto-approve -target=module.vpc

echo " "
echo " "
echo "Creating GitLab server and token"

terraform apply -auto-approve -target=module.gitlab_server

echo " "
echo " "
echo "Checking if the GitLab server is ready..."
echo " "
echo " "

TOKEN_FILE="./gitlab_token.txt"
IP_FILE="./gitlab_server_ip.txt"
MAX_WAIT_TIME=600 # Maximum wait time in seconds
INTERVAL=10       # Interval between checks in seconds

if [ ! -f "$IP_FILE" ]; then
    echo "IP file does not exist. Exiting."
    exit 1
fi

GITLAB_IP=$(cat "$IP_FILE")
GITLAB_URL="http://${GITLAB_IP}" # Construct the GitLab URL

START_TIME=$(date +%s)


# Check if the GitLab server is ready
while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))

    if [ $ELAPSED_TIME -ge $MAX_WAIT_TIME ]; then
        echo "GitLab server did not become ready within $MAX_WAIT_TIME seconds. Exiting."
        exit 1
    fi

    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" ${GITLAB_URL}/users/sign_in)
    if [ "$HTTP_STATUS" -eq 200 ]; then
        echo "GitLab server is ready."
        break
    else
        echo "Waiting for GitLab server to be ready..."
        sleep $INTERVAL
    fi
done


echo " "
echo " "
echo "Creating everything else"

terraform apply -auto-approve
