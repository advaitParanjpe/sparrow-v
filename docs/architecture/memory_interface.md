# Scalar Memory Interface

Both interfaces have independent request and response handshakes. A sender must keep every request field stable while `*_req_valid` is high and `*_req_ready` is low. A response remains valid until the core asserts `*_resp_ready`.

| Port | Request | Response | Limit |
| --- | --- | --- | --- |
| Instruction | `imem_req_valid`, `imem_req_ready`, 32-bit byte `imem_req_addr` | `imem_resp_valid`, `imem_resp_ready`, 32-bit instruction | One outstanding request |
| Data | valid/ready, word-aligned byte address, write flag, 32-bit data, 4-bit strobe | valid/ready, 32-bit read data | One outstanding request |

Data is little-endian. `wstrb[0]` controls address byte 0. The Phase 1 test memory deliberately adds response latency and periodically deasserts request ready. It is a verification model, not a scratchpad implementation.
