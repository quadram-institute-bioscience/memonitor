# Package
version       = "0.1.0"
author        = "Andrea Telatin"
description   = "Cross-platform memory monitoring utilities for Nim programs"
license       = "MIT"
srcDir        = "."
installExt    = @["nim"]
skipDirs      = @["tests"]

# Dependencies
requires "nim >= 1.6.0"

# Tasks
task docs, "Generate documentation":
  exec "nim doc --project --index:on --git.url:https://github.com/quadram-institute-bioscience/memonitor --out:docs memonitor.nim"

task test, "Run tests":
  exec "nim c -r tests/test_memonitor.nim"
