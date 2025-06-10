## Memory Monitor Module
## 
## Cross-platform memory monitoring utilities for Nim programs.
## Provides functions to get process RAM usage and system memory information.
##
## Example:
## ```nim
## import memonitor
## 
## let memInfo = getMemInfo()
## echo "Process uses: ", memInfo.processRamMB, " MB"
## echo "System has: ", memInfo.freeRamMB, " MB free"
## 
## # Monitor memory usage around some operation
## let before = getProcessRamMB()
## # ... do memory-intensive work ...
## let after = getProcessRamMB()
## echo "Memory increased by: ", after - before, " MB"
## ```

import os, strutils, osproc

type
  MemInfo* = object
    ## Memory information structure
    processRamMB*: float    ## Process RAM usage in MB (-1 if unable to determine)
    freeRamMB*: float       ## System free RAM in MB (-1 if unable to determine)
    totalRamMB*: float      ## Total system RAM in MB (-1 if unable to determine)
    usedSystemPercent*: float ## Percentage of system RAM used (-1 if unable to determine)

proc getProcessRamMB*(): float =
  ## Get current process RAM usage in megabytes.
  ## Returns -1.0 if unable to determine.
  
  when defined(linux):
    try:
      # Linux: Read from /proc/self/status
      let statusContent = readFile("/proc/self/status")
      for line in statusContent.splitLines():
        if line.startsWith("VmRSS:"):
          let parts = line.split()
          if parts.len >= 2:
            return parseFloat(parts[1]) / 1024.0  # Convert KB to MB
    except:
      discard
  
  elif defined(macosx):
    try:
      # macOS: Use ps command to get memory usage
      let output = execProcess("ps -o rss= -p " & $getCurrentProcessId())
      let rssKB = parseFloat(output.strip())
      return rssKB / 1024.0  # Convert KB to MB
    except:
      discard
  
  elif defined(windows):
    try:
      # Windows: Use tasklist command
      let pid = getCurrentProcessId()
      let output = execProcess("tasklist /fi \"PID eq " & $pid & "\" /fo csv")
      let lines = output.splitLines()
      if lines.len > 1:
        let fields = lines[1].split(",")
        if fields.len >= 5:
          # Memory usage is typically in the 5th field
          var memStr = fields[4].replace("\"", "").replace(",", "").replace(" K", "")
          let memKB = parseFloat(memStr)
          return memKB / 1024.0  # Convert KB to MB
    except:
      discard
  
  # Fallback: Try generic ps command for Unix-like systems
  try:
    when defined(posix):
      let output = execProcess("ps -o rss= -p " & $getCurrentProcessId())
      let rssKB = parseFloat(output.strip())
      return rssKB / 1024.0
  except:
    discard
  
  return -1.0

proc getSystemMemMB*(): tuple[free, total: float] =
  ## Get system memory information in megabytes.
  ## Returns (free_ram, total_ram) tuple.
  ## Returns (-1.0, -1.0) if unable to determine.
  
  when defined(linux):
    try:
      # Linux: Read from /proc/meminfo
      let meminfoContent = readFile("/proc/meminfo")
      var memTotal, memAvailable, memFree, memBuffers, memCached: float = 0.0
      
      for line in meminfoContent.splitLines():
        if line.startsWith("MemTotal:"):
          let parts = line.split()
          if parts.len >= 2:
            memTotal = parseFloat(parts[1]) / 1024.0  # Convert KB to MB
        elif line.startsWith("MemAvailable:"):
          let parts = line.split()
          if parts.len >= 2:
            memAvailable = parseFloat(parts[1]) / 1024.0  # Convert KB to MB
        elif line.startsWith("MemFree:"):
          let parts = line.split()
          if parts.len >= 2:
            memFree = parseFloat(parts[1]) / 1024.0  # Convert KB to MB
        elif line.startsWith("Buffers:"):
          let parts = line.split()
          if parts.len >= 2:
            memBuffers = parseFloat(parts[1]) / 1024.0  # Convert KB to MB
        elif line.startsWith("Cached:"):
          let parts = line.split()
          if parts.len >= 2:
            memCached = parseFloat(parts[1]) / 1024.0  # Convert KB to MB
      
      # If MemAvailable is not available, calculate it as Free + Buffers + Cached
      if memAvailable == 0.0 and memFree > 0.0:
        memAvailable = memFree + memBuffers + memCached
      
      if memTotal > 0.0 and memAvailable >= 0.0:
        return (memAvailable, memTotal)
    except:
      discard
  
  elif defined(macosx):
    try:
      # macOS: Use vm_stat and sysctl commands
      let vmOutput = execProcess("vm_stat")
      let sysctlOutput = execProcess("sysctl hw.memsize")
      
      # Parse total memory from sysctl
      var totalBytes: float = 0.0
      for line in sysctlOutput.splitLines():
        if "hw.memsize:" in line:
          let parts = line.split(":")
          if parts.len >= 2:
            totalBytes = parseFloat(parts[1].strip())
            break
      
      # Parse memory statistics from vm_stat
      var freePages, inactivePages, speculativePages: float = 0.0
      
      for line in vmOutput.splitLines():
        let cleanLine = line.strip()
        if cleanLine.startsWith("Pages free:"):
          let numStr = cleanLine.split(":")[1].strip().replace(".", "")
          try:
            freePages = parseFloat(numStr)
          except:
            discard
        elif cleanLine.startsWith("Pages inactive:"):
          let numStr = cleanLine.split(":")[1].strip().replace(".", "")
          try:
            inactivePages = parseFloat(numStr)
          except:
            discard
        elif cleanLine.startsWith("Pages speculative:"):
          let numStr = cleanLine.split(":")[1].strip().replace(".", "")
          try:
            speculativePages = parseFloat(numStr)
          except:
            discard
      
      # Get page size dynamically
      let pageSizeOutput = execProcess("sysctl hw.pagesize")
      var pageSize: float = 4096.0  # Default fallback
      
      for line in pageSizeOutput.splitLines():
        if "hw.pagesize:" in line:
          let parts = line.split(":")
          if parts.len >= 2:
            try:
              pageSize = parseFloat(parts[1].strip())
            except:
              discard
            break
      
      let totalMB = totalBytes / (1024.0 * 1024.0)
      # Available memory includes free + inactive + speculative pages
      let availableMB = (freePages + inactivePages + speculativePages) * pageSize / (1024.0 * 1024.0)
      
      return (availableMB, totalMB)
    except:
      discard
  
  elif defined(windows):
    try:
      # Windows: Use wmic command
      let totalOutput = execProcess("wmic computersystem get TotalPhysicalMemory /value")
      let availOutput = execProcess("wmic OS get FreePhysicalMemory /value")
      
      var totalBytes, freeKB: float = 0.0
      
      # Parse total memory
      for line in totalOutput.splitLines():
        if "TotalPhysicalMemory=" in line:
          let value = line.split("=")[1].strip()
          if value.len > 0:
            totalBytes = parseFloat(value)
            break
      
      # Parse free memory
      for line in availOutput.splitLines():
        if "FreePhysicalMemory=" in line:
          let value = line.split("=")[1].strip()
          if value.len > 0:
            freeKB = parseFloat(value)
            break
      
      let totalMB = totalBytes / (1024.0 * 1024.0)
      let freeMB = freeKB / 1024.0
      
      return (freeMB, totalMB)
    except:
      discard
  
  return (-1.0, -1.0)

proc getMemInfo*(): MemInfo =
  ## Get complete memory information for both process and system.
  ## This is the main function to use for comprehensive memory monitoring.
  
  let processRam = getProcessRamMB()
  let (freeRam, totalRam) = getSystemMemMB()
  
  var usedPercent: float = -1.0
  if freeRam >= 0 and totalRam >= 0:
    usedPercent = ((totalRam - freeRam) / totalRam) * 100.0
  
  return MemInfo(
    processRamMB: processRam,
    freeRamMB: freeRam,
    totalRamMB: totalRam,
    usedSystemPercent: usedPercent
  )

proc `$`*(info: MemInfo): string =
  ## String representation of MemInfo for easy printing
  result = "MemInfo("
  if info.processRamMB >= 0:
    result.add("process: " & info.processRamMB.formatFloat(ffDecimal, 2) & " MB")
  else:
    result.add("process: unknown")
  
  if info.freeRamMB >= 0:
    result.add(", free: " & info.freeRamMB.formatFloat(ffDecimal, 2) & " MB")
  else:
    result.add(", free: unknown")
    
  if info.totalRamMB >= 0:
    result.add(", total: " & info.totalRamMB.formatFloat(ffDecimal, 2) & " MB")
  else:
    result.add(", total: unknown")
    
  if info.usedSystemPercent >= 0:
    result.add(", system used: " & info.usedSystemPercent.formatFloat(ffDecimal, 1) & "%")
  
  result.add(")")

proc formatMemMB*(memMB: float): string =
  ## Format memory value with appropriate units (MB/GB)
  if memMB < 0:
    return "unknown"
  elif memMB < 1024:
    return memMB.formatFloat(ffDecimal, 2) & " MB"
  else:
    return (memMB / 1024.0).formatFloat(ffDecimal, 2) & " GB"

proc isMemInfoAvailable*(): tuple[process, system: bool] =
  ## Check which memory monitoring capabilities are available on this system
  let memInfo = getMemInfo()
  return (memInfo.processRamMB >= 0, memInfo.totalRamMB >= 0)

template withMemoryMonitoring*(body: untyped): untyped =
  ## Template to monitor memory usage around a block of code
  ## Usage:
  ## ```nim
  ## withMemoryMonitoring:
  ##   # Your memory-intensive code here
  ##   var data = newSeq[int](1000000)
  ## ```
  let memBefore = getProcessRamMB()
  body
  let memAfter = getProcessRamMB()
  
  if memBefore >= 0 and memAfter >= 0:
    let increase = memAfter - memBefore
    echo "Memory usage increased by: ", formatMemMB(increase)
  else:
    echo "Memory monitoring not available on this system"

proc getNimMemInfo*(): tuple[used, free: int] =
  ## Get Nim's internal memory statistics if available
  ## Returns (-1, -1) if not available
  when declared(getTotalMem) and declared(getFreeMem):
    return (getTotalMem(), getFreeMem())
  else:
    return (-1, -1)

# Example usage demonstration
when isMainModule:
  echo "Memory Monitor Module Demo"
  echo "========================="
  
  # Check availability
  let (processAvail, systemAvail) = isMemInfoAvailable()
  echo "Process monitoring available: ", processAvail
  echo "System monitoring available: ", systemAvail
  
  # Get current memory info
  let memInfo = getMemInfo()
  echo "\nCurrent memory status:"
  echo memInfo
  
  # Monitor memory around allocation
  echo "\nTesting memory allocation..."
  withMemoryMonitoring:
    var testData = newSeq[int](1_000_000)  # Allocate ~8MB
    for i in 0..<testData.len:
      testData[i] = i
    echo "Allocated and filled 1M integers"
  
  # Show Nim internal memory info
  let (nimUsed, nimFree) = getNimMemInfo()
  if nimUsed >= 0:
    echo "\nNim internal memory: used=", nimUsed, " bytes, free=", nimFree, " bytes"
