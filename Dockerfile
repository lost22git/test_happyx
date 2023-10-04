FROM nimlang/nim:2.0.0-alpine as builder

WORKDIR /project

ARG http_proxy=""

RUN export HTTP_PROXY=${http_proxy} \
  && export HTTPS_PROXY=${http_proxy}

RUN git config --global http.proxy ${http_proxy} && \
  git config --global https.proxy ${http_proxy}

RUN apk add --update --no-cache --force-overwrite \
  sqlite-dev \
  sqlite-static

COPY ./test_happyx.nimble ./

RUN nimble install -d -y

COPY . .

RUN nimble build \ 
  -d:beast \
  -d:release \
  --dynlibOverride:sqlite3 \
  --passL:/usr/lib/libsqlite3.a \
  --passL:-lpthread \
  --passL:-static \
  --verbose -y



FROM alpine:latest

WORKDIR /app

COPY --from=builder --chmod=777 /project/bin/test_happyx ./bin/
COPY --from=builder /project/fighter.db ./

EXPOSE 5000/tcp

ENTRYPOINT ["./bin/test_happyx"]
