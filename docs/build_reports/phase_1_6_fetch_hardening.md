# Phase 1.6 Fetch Hardening Report

## Implemented

The instruction-side interface now has a request buffer and outstanding-request metadata with a one-bit epoch. Redirects no longer clear or mutate a stalled request. Old accepted responses are discarded by epoch, while their transaction is completed normally.

## Validation status

The existing delayed/backpressured directed scalar simulation passes after the change, as do Verilator lint and the reference-model unit tests. The retirement trace remains exposed by the core.

## Remaining work

The project does not yet have trace-vs-reference RTL comparison, randomized legal-program regression, focused redirect/reset stress tests, or measured CPI. Those are still required for Phase 1.6 acceptance; the scalar core remains not ready for vector integration.
