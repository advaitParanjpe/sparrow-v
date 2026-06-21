# Phase 1.8a Pipeline Skeleton

`rv32_core_pipe` is an isolated development core. It owns IF, DX, MW, request, and outstanding valid bits in one sequential block. `mw_ready=!mw_v||mw_complete`; `dx_to_mw=dx_v&&mw_ready`; `if_to_dx=if_v&&dx_ready`; `mw_retire=mw_v&&mw_complete`. Only ADDI and ECALL are supported; all other instructions trap. Next step: extend payload/control and prove redirect/memory behavior before integration.
