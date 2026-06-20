# Contributing to Sparrow-V

The preserved files in `sparrow-v-project-plan/` are the planning specification. Do not silently turn an open architectural question into implementation behavior. Record material choices in `docs/decisions/` first, then update the relevant architecture and interface documents.

Keep synthesizable SystemVerilog in `rtl/`, verification assets in `tb/`, generated artifacts in ignored build/result locations, and software/reference tools outside RTL directories. Follow `sparrow-v-project-plan/docs/14_coding_and_design_rules.md` for implementation conventions.

Before submitting a change, run:

```sh
make check
make docs-check
make test
```

Do not claim functionality, measurements, or tool results without reproducible artifacts and commands.
