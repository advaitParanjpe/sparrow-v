# Scalar-to-Vector Boundary, v1

## Scope

This is the approved protocol contract and the basis of an implemented,
experimental integration in `rv32_core_pipe`. It is not a vector ISA.
`rv32_core.sv` remains unchanged and treats Custom-0 as illegal. The pipe
implementation recognizes only these test encodings under Custom-0 (`0001011`,
opcode `0x0b`): `funct3=000` is successful scalar-result stub execution,
`001` is successful vector-only completion, `010` is exceptional, `011` is
`VADD8` vector-only completion, `100` is `VDOT8` scalar-result completion,
`101` is `VLOAD32`, `110` is `VSTORE32`, and `111` is `VSDOT8`.
They are experimental test encodings, not
the final Sparrow-V ISA.

## Command channel

The scalar extension adapter drives a decoupled command channel.  Acceptance
is exactly `vec_cmd_valid && vec_cmd_ready` on a rising clock edge.  The
adapter holds every command field stable until acceptance.  `vec_cmd_ready`
may be low for arbitrary finite time and must be low while one command is
outstanding.  Reset deasserts `vec_cmd_valid`; no command is accepted during
reset.

| Field | Width | v1 meaning |
| --- | ---: | --- |
| `vec_cmd_valid`, `vec_cmd_ready` | 1, 1 | Command handshake. |
| `vec_cmd_op_class` | 4 | Experimental operation class. The current pipe maps `funct3` into this field: 0=result stub, 1=vector-only stub, 2=exception stub, 3=VADD8, 4=VDOT8, 7=VSDOT8. |
| `vec_cmd_funct` | 8 | Opaque function/immediate selector for the later ISA. |
| `vec_cmd_vs1`, `vec_cmd_vs2`, `vec_cmd_vd` | 5 each | Opaque vector-register indices; their implemented range is deferred. |
| `vec_cmd_rs1_data`, `vec_cmd_rs2_data` | 32 each | Captured scalar operands. |
| `vec_cmd_rs1_valid`, `vec_cmd_rs2_valid` | 1 each | Whether the corresponding captured operand is meaningful. |
| `vec_cmd_rd`, `vec_cmd_rd_we` | 5, 1 | Requested scalar result destination and intent. `rd=0` is accepted but never writes x0. |
| `vec_cmd_imm` | 32 | Decoded immediate/function payload; interpretation is deferred. |
| `vec_cmd_pc` | 32 | Issuing scalar instruction PC, used for precise exception reporting. |
| `vec_cmd_id` | 1 | Fixed zero in v1. It identifies the sole outstanding slot and reserves an explicit extension point; it is not a tag namespace. |

There is no privilege/trap-context field in v1 because Phase 1 has no
privileged execution context.  A later privileged extension must revise this
record rather than infer context from scalar internals.

## Completion channel

The engine drives `vec_cpl_valid`; the scalar adapter drives
`vec_cpl_ready`. A completion is accepted exactly when both are high. The
engine holds all completion fields stable until accepted. The current adapter
accepts immediately by default; its test-only `VEC_CPL_READY_STALL` parameter
exercises finite completion backpressure without changing the interface.

| Field | Width | v1 meaning |
| --- | ---: | --- |
| `vec_cpl_valid`, `vec_cpl_ready` | 1, 1 | Completion handshake. |
| `vec_cpl_id` | 1 | Must be zero and match the outstanding slot. |
| `vec_cpl_status` | 2 | `00=success`, `01=vector exception`, `10=illegal operation`, `11=reserved`. |
| `vec_cpl_result_valid`, `vec_cpl_result_data` | 1,32 | Scalar result. A vector-only operation uses `result_valid=0`; no fabricated scalar writeback occurs. |
| `vec_cpl_exception_cause` | 32 | Valid only for non-success status; mapped by the scalar adapter to the documented trap owner/cause policy of the later ISA milestone. |

## v1 ordering, retirement, exceptions, redirects, and reset

V1 is one-command, blocking, in-order, and non-speculative.  The scalar
instruction is dispatched only after all older scalar work has completed.
After command acceptance, scalar issue stops; its destination is reserved in
adapter state, not written early.  The vector instruction retires only on an
accepted successful completion.  If `result_valid && rd_we && rd != 0`, the
captured completion result is written at that retirement event.  x0 remains
zero.

A non-success accepted completion causes a precise scalar trap at
`vec_cmd_pc`: it has no scalar writeback, no successful vector retirement, and
no younger scalar work can become visible.  Tags add no value with one
outstanding command; `id` is fixed zero only to make a future tagged revision
explicit and backwards distinguishable.

No redirect or scalar trap can arise after a command is accepted because the
scalar pipeline is blocked and all older work already completed.  Before
acceptance, the instruction has not issued and normal scalar redirect/trap
rules discard it.  Reset cancels the outstanding command architecturally:
the vector engine must clear its active state and suppress any completion; no
cancellation acknowledgement is needed in v1 because reset is system-wide.

The adapter-focused endpoint is `rtl/vector/rv32_vec_stub_engine.sv`, instantiated
with deterministic latency 3 in focused integration tests. It captures only
the operation class and scalar operands, returns `rs1 + rs2` for class 0,
returns a result-invalid success for class 1, and returns status `01` with
cause 2 for class 2. It has no vector register file, vector ALU, vector-memory
interface, or sparse logic. Focused targets are
`test-scalar-pipe-vec-stub`, `test-scalar-pipe-vec-cmd-stall`,
`test-scalar-pipe-vec-cpl-stall`, `test-scalar-pipe-vec-exception`,
`test-scalar-pipe-vec-no-writeback`, `test-scalar-pipe-vec-reset`,
`test-scalar-pipe-vec-wrong-path`, and aggregate
`test-scalar-pipe-vec-stub-all`.

The real experimental endpoint is `rtl/vector/rv32_vec_vadd_engine.sv`, the
sole owner of 32x32-bit vector state. Custom-0 `funct3=011` maps to VADD8
class 3 and returns a result-invalid successful completion, committing its
vector-register write exactly on completion handshake. `funct3=100` maps to
VDOT8 class 4, carries `rs1`/`rs2` as vector sources and `rd` as scalar
destination, returns a result-valid successful completion, and never writes
vector state. Its four-lane INT8 behavior and test-only debug ports are
specified in [vector VADD8](vector_vadd8.md).

`funct3=111` is `VSDOT8`; `vec_cmd_funct[7:5]` transports its metadata. It
returns a scalar result or precise cause 18 for reserved metadata patterns;
compressed weights, ordering, and completion-gated accounting are specified in
[sparse INT8 dot product](vector_vsdot8.md).

## Implemented vector scratchpad boundary

`rv32_vec_vadd_engine` now owns the sole 256-byte vector scratchpad as well as
the sole vector register file. It is not connected to scalar `dmem`. `VLOAD32`
uses I-type Custom-0 fields: `rd=vd`, `rs1=scalar base`, and signed
`imm[11:0]=instr[31:20]`. `VSTORE32` uses S-type fields: `rs2=vs`,
`rs1=scalar base`, and signed `imm={instr[31:25],instr[11:7]}`. Both use
`effective_address = rs1_data + sign_extended_imm`.

Only aligned byte addresses `0x00000000` through `0x000000fc` succeed; bytes
are little-endian. Read data is captured at command acceptance after the
fixed latency, while a load register write and store byte write both commit
only with successful completion handshake. Reset clears pending work without
either write. Misalignment completes exceptionally with cause 16; range or
32-bit arithmetic wrap completes exceptionally with cause 17. The bounded
`dbg_spad_*` ports initialize and observe aligned words for testbench use only.

## State boundary and deferrals

Vector registers are owned solely by the vector engine.  The three command
indices transport references only; scalar operands cross as captured 32-bit
values and scalar results return only through completion.  Vector state resets
with the engine, but whether register contents are architecturally defined
after reset is deferred.  Any debug state is separately specified and is not a
scalar ABI.

Vector register count/width, masks, tail policy, lane arithmetic, sparse
metadata, detailed op semantics, and software encodings remain deferred to
their existing or later ISA ADRs.
