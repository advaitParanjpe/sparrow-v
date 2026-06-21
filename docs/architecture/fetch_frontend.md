# Phase 1.6 Fetch Front End

The scalar front end now separates `pc` (the next architectural fetch address) from a registered request buffer (`req_valid`, `req_addr`, `req_epoch`) and accepted request metadata (`fetch_pending`, `out_addr`, `out_epoch`). The request address is driven only from `req_addr`, so it remains stable for every `imem_req_valid && !imem_req_ready` interval.

`fetch_epoch` changes on branch/jump and trap redirects. A request already accepted under an old epoch is allowed to return; its response is discarded when `out_epoch != fetch_epoch`. A stalled request is never modified by redirect. Once the stale transaction has completed, the front end creates a request for the redirected `pc`.

This supports safe IF/MW overlap and leaves at most one accepted request outstanding. The present test suite validates the original directed program under delayed/backpressured memory; dedicated trace-CPI and randomized redirect regressions remain required before performance claims.
