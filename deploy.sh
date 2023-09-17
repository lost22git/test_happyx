#!/usr/bin/env bash

nimble build -d:release -d:beast --mm:refc && ./test_happyx
