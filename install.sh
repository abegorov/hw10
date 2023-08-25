#!/bin/bash

JENKINS_KEYFILE="$HOME/.ssh/jenkins_agent_key"
JENKINS_PUBKEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFB3Rq/cwFMYwA4VKbdEpoaxB5Rz8kC04WA1rqLPiGwU jenkins"

set -xe

function install_docker() {
    apt update
    apt install --yes ca-certificates curl gnupg
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg \
        | gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo deb [arch=$(dpkg --print-architecture) \
            signed-by=/etc/apt/keyrings/docker.gpg] \
            https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
            $(. /etc/os-release && echo "$VERSION_CODENAME") stable \
        > /etc/apt/sources.list.d/docker.list
    apt update
    apt install --yes docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

function install_jenkins() {
    install_docker
    docker compose --file jenkins.yml up -d
    if [[ ! -f "$JENKINS_KEYFILE" ]]; then
        ssh-keygen -q -t ed25519 -f "$JENKINS_KEYFILE" -N ""
    fi
}

function install_agent() {
    install_docker
    cat <<EOF > /etc/docker/daemon.json
{
  "insecure-registries" : ["10.129.0.8:8080"]
}
EOF
    systemctl reload docker
    apt install --yes openjdk-11-jre-headless
    if ! grep --fixed-strings --line-regexp "$JENKINS_PUBKEY" "/root/.ssh/authorized_keys" > /dev/null; then
        echo "$JENKINS_PUBKEY" >> "/root/.ssh/authorized_keys"
    fi
}

function install_nexus()
{
    install_docker
    docker compose --file nexus.yml up -d
}

case "$1" in
    jenkins)
        install_jenkins
        ;;
    agent)
        install_agent
        ;;
    nexus)
        install_nexus
        ;;
    *)
        echo "$0 jenkins|agent|nexus"
        echo ""
        ;;
esac
