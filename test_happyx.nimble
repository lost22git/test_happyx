# Package

version       = "0.1.0"
author        = "lost22git"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @["test_happyx"]
binDir        = "bin"

# Dependencies

requires "nim >= 2.0.0", "happyx", "mapster >= 1.1.0", "debby", "jsony"

# ------ 参考：https://github.com/ee7/binary-size?tab=readme-ov-file#details

task release, "Build binary with release mode":
  const cmd = "nimble build --verbose --mm:refc -d:beast -d:release && mv bin/test_happyx bin/test_happyx_release"
  exec cmd

task release_lto, "Build binary with release mode and lto":
  const cmd = "nimble build --verbose --mm:refc -d:beast -d:release --passC:-flto --passL:-flto && mv bin/test_happyx bin/test_happyx_release_lto"
  exec cmd

task zigcc, "Build static-linking binary with zig cc":
  const cmd = """nim c --mm:refc -d:beast -d:release --cc:clang --clang.exe:zigcc --clang.linkerexe:zigcc --passC="-target x86_64-linux-musl" --passL="-target x86_64-linux-musl" --dynlibOverride:sqlite3 --passL:libsqlite3.a src/test_happyx.nim && mv src/test_happyx bin/test_happyx_release_zigcc"""
  exec cmd
