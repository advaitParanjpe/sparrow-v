# Benchmarks and Evaluation

## Required configurations

### Scalar baseline

RV32I implementation without vector instructions.

### Dense vector

Same scalar core with vector unit enabled, but sparse instruction disabled.

### Sparse-aware vector

Dense vector features plus 2:4 sparse execution.

### Optional fixed-function baseline

tinyNPU may be included as a separate accelerator comparison if integration and benchmark fairness are documented.

## Microbenchmarks

- vector add;
- vector multiply;
- dot product;
- reduction sum;
- vector load/store;
- dense matrix-vector multiply;
- 2:4 sparse matrix-vector multiply;
- bank-conflict stress;
- partial-vector execution.

## End-to-end benchmark

Choose one primary IoT workload. Recommended first choice: vibration-fault classification using a small quantized MLP or 1D feature pipeline.

## Metrics

### Performance

- total cycles;
- retired scalar instructions;
- retired vector instructions;
- cycles per workload;
- vector busy cycles;
- scalar stall cycles;
- scratchpad stall cycles.

### Sparse efficiency

- dense-equivalent multiplies;
- actual multiplies;
- operations skipped;
- dense weight bytes;
- sparse value bytes;
- metadata bytes;
- net memory-traffic reduction.

### Utilization

- active lane cycles;
- total available lane cycles;
- vector-lane utilization;
- bank utilization;
- multiplier utilization.

### Hardware cost

- generic synthesis cell count;
- LUTs/FFs/BRAMs for FPGA;
- standard-cell area for ASIC-style flow;
- critical path and Fmax;
- estimated power if available.

### Derived metrics

- speedup over scalar;
- sparse speedup over dense vector;
- area overhead;
- throughput per area;
- operations per cycle;
- operations per second at achieved Fmax;
- skipped operations per area overhead.

## Experimental discipline

- Use identical inputs across configurations.
- Use the same quantized model wherever possible.
- Separate algorithmic accuracy changes from hardware speedup.
- Record tool versions and configuration parameters.
- Do not compare against tinyNPU unless data formats and work performed are equivalent.
- Report negative results and regressions.

