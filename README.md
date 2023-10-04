# test-happyx

an example of happyx

- sqlite
- static linking
- docker multi-stage build

## Installation

TODO: Write installation instructions here

## Usage

### zig cc

- write a shell script and copy to /usr/local/bin

zigcc content

```shell
#!/usr/bin/env bash

zig cc $@

```

```shell
cp zigcc /usr/local/bin
```

- build app with zigcc

```shell
nimble zigcc

```

- run app

```shell
./bin/test_happyx_release_zigcc
```

### Docker

- build docker image `test-happyx`

```shell
docker build -t test-happyx --build-arg http_proxy=$HTTP_PROXY  .
```

- create docker network `mnet`

```shell
docker network create -o com.docker.network.bridge.name=mnet mnet
```

- run docker container `test-happyx` in network `mnet`

```shell
docker run -dit --name test-happyx --net mnet -p 5000:5000/tcp test-happyx
```

### Docker compose

```shell
docker compose up -d
```

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/lost22git/test_happyx/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [lost22git](https://github.com/lost22git) - creator and maintainer
