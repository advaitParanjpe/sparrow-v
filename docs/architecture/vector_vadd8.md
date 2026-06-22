# Experimental Vector Register File and VADD8

`rv32_vec_vadd_engine.sv` owns 32 vector registers (`v0`–`v31`). Each is a
32-bit value with four little-endian 8-bit lanes. Reads are combinational;
the sole architectural write is synchronous and occurs on a successful
completion handshake. `v0` is an ordinary writable vector register.

Custom-0 opcode `0x0b`, `funct3=011`, is the experimental `VADD8 vd, vs1,
vs2` encoding. Each destination lane is `(vs1[i] + vs2[i]) mod 256`. It has
no scalar writeback. At command acceptance, `vs1` and `vs2` are consumed by
combinational vector-register reads; the computed result and `vd` are retained
until completion acceptance. The result is invisible until completion acceptance,
which makes source/destination aliases use pre-instruction state and lets
reset cancel an uncommitted write. Vector register contents are intentionally
not reset; verification initializes every observed register.

Other Custom-0 `funct3` values are not VADD8 and retain the pipe's precise
illegal-instruction behavior.

The `dbg_*` ports are bounded simulation/testbench-only register access for
initialization and observation. `dbg_vreg_write_*` exposes the sole
completion-handshake vector write for test accounting. They are not a scalar
interface, software ABI, or ISA feature. There is no vector memory, masks,
wider elements, or other vector arithmetic in this milestone.
