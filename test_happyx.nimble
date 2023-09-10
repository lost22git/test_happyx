# Package

version       = "0.1.0"
author        = "lost22git"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @["test_happyx"]


# Dependencies

requires "nim >= 2.0.0", "happyx", "mapster >= 1.1.0", "stdx"
