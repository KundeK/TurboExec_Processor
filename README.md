# TurboExec_Processor

An advanced out-of-order RISC-V processor implementation featuring explicit register renaming (ERR) architecture and sophisticated execution optimizations.

## Overview

TurboExec is a complete out-of-order execution processor supporting the RV32IM instruction set. The design implements modern microarchitectural techniques including dynamic instruction scheduling, speculative execution, and advanced branch prediction to achieve high instruction-level parallelism.

## Key Features

### Core Architecture
- **Out-of-Order Execution**: Explicit Register Renaming (ERR) style architecture
- **Dynamic Scheduling**: Reservation stations for flexible instruction dispatch
- **Register Renaming**: Physical register file with freelist management
- **Reorder Buffer**: Maintains program order for correct instruction commit
- **Multiple Functional Units**: ALU, multiply/divide, memory, and branch units

### Memory Hierarchy
- **Instruction Cache**: 4-way set-associative with cacheline buffer
- **Data Cache**: Write-allocate, write-back policy
- **Cache Arbiter**: Priority-based arbitration between I-cache and D-cache
- **Burst Memory Interface**: Cacheline adapter for DRAM burst transactions

### Advanced Optimizations Attempted
- **Gshare Branch Predictor**: Global history with XOR indexing
- **Branch Target Buffer (BTB)**: Fast target address prediction
- **Next-Line Prefetcher**: Reduces instruction cache miss penalties
- **Early Branch Recovery**: Checkpoint-based misprediction recovery

## Performance Metrics

- **IPC**: 0.2797 on coremark benchmark
- **Frequency**: 100MHz
- **Area**: 213,952 µm²
- **Instruction Set**: Complete RV32IM support

## Implementation Details

### Technology Stack
- **HDL**: SystemVerilog
- **IP Integration**: Synopsys DesignWare for multiply/divide units
- **Memory Model**: Banked burst DRAM with out-of-order responses
- **Synthesis**: Meets timing at 100MHz target frequency

### Pipeline Stages
1. **Fetch**: Instruction fetch with cacheline buffer
2. **Decode**: Instruction decode and dependency analysis
3. **Rename**: Register renaming and physical register allocation
4. **Dispatch**: Instruction dispatch to reservation stations
5. **Issue**: Dynamic instruction issue to functional units
6. **Execute**: Parallel execution in specialized functional units
7. **Writeback**: Result broadcast via common data bus
8. **Commit**: In-order instruction commit from reorder buffer

## Benchmark Results

| Test | Result | IPC | Area (µm²) | Power (mW) |
|------|--------|-----|------------|------------|
| coremark | ✅ | 0.2797 | 213,952 | - |
| aes_sha | ✅ | 0.2849 | 213,952 | - |
| cnn | ✅ | 0.2585 | 213,952 | - |
| compression | ✅ | 0.3409 | 213,952 | - |
| fft | ✅ | 0.2655 | 213,952 | - |

## Architecture Diagram

The processor implements a classic OoO pipeline with specialized components for instruction fetching, decoding, register renaming, instruction scheduling, execution, and commitment. The design features separate instruction and data caches interfacing with main memory through an arbiter and cacheline adapter system.
