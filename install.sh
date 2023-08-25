#!/bin/bash

JENKINS_KEYFILE="$HOME/.ssh/jenkins_agent_key"
JENKINS_PUBKEY=""

set -xe

function install_docker() {
    apt update
    apt install ca-certificates curl gnupg
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg
        | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo deb [arch=$(dpkg --print-architecture) \
            signed-by=/etc/apt/keyrings/docker.gpg] \
            https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
            $(. /etc/os-release && echo "$VERSION_CODENAME") stable \
        > /etc/apt/sources.list.d/docker.list
    apt update
    apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

function install_jenkins() {
    install_docker
    docker compose --file jenkins.yml up
    if [[ -f "$JENKINS_KEYFILE" ]]; then
        ssh-keygen -q -t ed25519 -f "$JENKINS_KEYFILE" -N ""
    fi
}

function install_agent() {
    install_docker
    if ! grep --fixed-strings --line-regexp "$JENKINS_PUBKEY" "/root/.ssh/authorized_keys" > /dev/null; then
        echo "$JENKINS_PUBKEY" >> "/root/.ssh/authorized_keys"
    fi
}

function install_nexus()
{
    install_docker
    docker compose --file nexus.yml up
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
