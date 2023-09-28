#!/usr/bin/env bash
set -e

nimble build --verbose --mm:refc -d:beast -d:release

# ------ 使用 docker alpine 环境进行静态链接

# docker run -it --rm \
#   -v .:/project \
#   -w /project \
#   -e HTTP_PROXY=${HTTP_PROXY} \
#   -e HTTPS_PROXY=${HTTP_PROXY} \
#   nimlang/nim:2.0.0-alpine \
#   sh -c \
#   "apk add --update --no-cache --force-overwrite \
#   sqlite-dev \
#   sqlite-static && \
#   ls -ahl /usr/lib && \
#   git config --global --add safe.directory /project && \
#   nimble build \
#   --mm:refc \
#   -d:beast \
#   -d:release \
#   -d:nimDebugDlOpen \
#   --dynlibOverride:sqlite3 \
#   --passL:/usr/lib/libsqlite3.a \
#   --passL:-static \
#   --verbose -y"




