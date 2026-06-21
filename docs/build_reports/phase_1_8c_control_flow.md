# Phase 1.8c: Development Control Flow

`rv32_core_pipe.sv` implements BEQ, BNE, BLT, BGE, BLTU, BGEU, JAL, and JALR in the isolated development pipeline; `rv32_core.sv` is unchanged.

Branches resolve in DX from the stored DX PC and decoded B immediate. JAL/JALR write `PC+4`; JALR uses forwarded rs1, clears bit zero, and traps cause 0 when the resulting address is not four-byte aligned. Branches write no register.

Redirect has priority over IF-to-DX. A redirect increments a two-bit fetch generation, clears IF, prevents its instruction from entering DX, and changes the next request to the DX target. Every accepted request records its generation. An old-generation response is consumed and counted as stale, but cannot enter IF/DX. A held request remains address/generation stable until handshake; a redirect while held creates a pending redirect target and the just-accepted old request becomes stale.

The control test covers all branch conditions, signed/unsigned comparisons, non-taken and forward taken branches, JAL link/x0 behavior, and forwarded JALR base/link behavior. It measured 42 cycles, 13 normal retirements, 5 taken conditional branches, 1 non-taken branch, 8 redirects/flush cycles, and 16 stale responses in the always-ready response model. The redirect test holds a request under backpressure across a JAL redirect and checks stale-response discard and wrong-path write suppression.

The independent ADDI regression monitor is corrected: retirement cycles 5–20 are a maximum consecutive retirement run of 16, not 15. Remaining unsupported features are loads/stores, full privileged behavior, vectors, sparse/scratchpad logic, and production-core integration.
