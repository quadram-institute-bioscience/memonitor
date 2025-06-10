# memonitor

A cross-platform Nim library to monitor RAM usage in applications.

## Features

- Monitor process memory usage
- Get system memory information (free, total)
- Calculate memory usage percentages
- Format memory values with appropriate units (MB/GB)
- Works on Linux, macOS, and Windows
- Simple API with comprehensive memory information

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