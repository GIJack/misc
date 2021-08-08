#!/usr/bin/env bash
#
# get mail logs from dockerized mailcow
#
# Licensed: GPLv3 GI_Jack
DOCKER_IMAGE=postfix-mailcow
TIME=24h
docker logs --since ${TIME} $(docker ps -qf name=${DOCKER_IMAGE})
