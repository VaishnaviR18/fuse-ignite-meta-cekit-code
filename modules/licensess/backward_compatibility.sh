#!/bin/bash
set -euo pipefail

# Legacy locations

ln -s licenses.tar.gz /tmp

mkdir -p /opt/fuse-ignite/
tar -xzf /tmp/licenses.tar.gz -C /opt/fuse-ignite/
rm /tmp/licenses.tar.gz