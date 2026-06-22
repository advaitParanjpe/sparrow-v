# Experimental Vector Scratchpad and Transfers

The vector engine owns one 256-byte scratchpad, addressed as bytes from
`0x00000000` to `0x000000ff`. It stores 32-bit little-endian words; aligned
word starts are `0x00` through `0xfc`. Contents are intentionally unspecified
after reset, so verification initializes every inspected word through the
bounded test-only `dbg_spad_*` ports.

Custom-0 `funct3=101` encodes `VLOAD32 vd, offset(rs1)` with ordinary I-type
fields. `funct3=110` encodes `VSTORE32 vs, offset(rs1)` with ordinary S-type
fields. The engine adds a captured scalar base and sign-extended 12-bit
offset. It rejects unaligned effective addresses (cause 16), out-of-range
addresses, and arithmetic wrap (cause 17), with no memory or vector update.

The fixed engine latency is three cycles. A successful load captures its word
then writes `vd` only on completion handshake. A successful store captures
`vs` then writes exactly its four bytes only on completion handshake. Thus
completion backpressure and reset cannot expose early or duplicate state.
This is a tightly coupled experimental vector-only scratchpad, not scalar
memory, a cache, DMA interface, or a general vector ISA.
