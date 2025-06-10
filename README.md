# memonitor

[![Test](https://github.com/telatin/memonitor/actions/workflows/test.yml/badge.svg)](https://github.com/telatin/memonitor/actions/workflows/test.yml)
[![Nimble Directory](https://img.shields.io/badge/Nimble_Directory-memonitor-blue)](https://nimble.directory/pkg/memonitor)

## Features

- Monitor process memory usage
- Format memory values with appropriate units (MB/GB)
- Works on Linux, macOS, and Windows

## Installation

```
nimble install memonitor
```

## Usage

```nim
import memonitor

# Get complete memory information
let memInfo = getMemInfo()
echo "Process uses: ", memInfo.processRamMB, " MB"
echo "System has: ", memInfo.freeRamMB, " MB free of ", memInfo.totalRamMB, " MB total"
echo "System memory usage: ", memInfo.usedSystemPercent, "%"

# Format memory values with appropriate units
echo "Process RAM: ", formatMemMB(memInfo.processRamMB)  # "500.50 MB" or "1.25 GB"

# Monitor memory usage around an operation
withMemoryMonitoring:
  var data = newSeq[int](1_000_000)  # Allocate some memory
  # ... do memory-intensive work ...
```

## API Documentation

Generate documentation with:

```
nimble docs
```

## Running Tests

```
nimble test
```

## License

MIT
