#!/bin/sh
set -e

mkdir -p /opt/fuse-ignite/ && \
tar xvzf /tmp/licenses.tar.gz -C /opt/fuse-ignite/ && \
rm /tmp/licenses.tar.gz