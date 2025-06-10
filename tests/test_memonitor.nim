import unittest
import ../memonitor

suite "Memory Monitor Tests":
  test "getProcessRamMB returns valid data":
    let processRam = getProcessRamMB()
    check(processRam > 0.0)
    echo "Process RAM: ", formatMemMB(processRam)
  
  test "getSystemMemMB returns valid data":
    let (freeRam, totalRam) = getSystemMemMB()
    # System memory detection may fail in CI environments
    if freeRam >= 0.0 and totalRam > 0.0:
      check(freeRam <= totalRam)
      echo "System RAM - Free: ", formatMemMB(freeRam), ", Total: ", formatMemMB(totalRam)
    else:
      echo "System RAM - Free: unknown, Total: unknown"
  
  test "getMemInfo returns valid data":
    let info = getMemInfo()
    check(info.processRamMB > 0.0)
    # System memory may not be available in all CI environments
    if info.freeRamMB >= 0.0 and info.totalRamMB > 0.0:
      check(info.usedSystemPercent >= 0.0 and info.usedSystemPercent <= 100.0)
    echo "Memory Info: ", info
  
  test "isMemInfoAvailable returns expected values":
    let (processAvail, systemAvail) = isMemInfoAvailable()
    check(processAvail == true)
    # System availability may vary by platform and CI environment
    echo "Availability - Process: ", processAvail, ", System: ", systemAvail
  
  test "formatMemMB formats correctly":
    check(formatMemMB(500.0) == "500.00 MB")
    check(formatMemMB(1500.0) == "1.46 GB")
    check(formatMemMB(-1.0) == "unknown")
  
  test "withMemoryMonitoring works":
    var before = getProcessRamMB()
    withMemoryMonitoring:
      var data = newSeq[int](1_000_000)  # Allocate ~8MB
      for i in 0..<data.len:
        data[i] = i
    var after = getProcessRamMB()
    check(after >= before)  # Memory should increase or stay the same