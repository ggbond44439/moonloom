# CLI

The `moonloom` executable is a thin process wrapper around the reusable `cli`
package. Command parsing and rendering are testable without process I/O.

## Current commands

```text
moonloom --help
moonloom version
```

The command names for Multibase, Multihash, CID, and Multiaddr are already
reserved and routed by the top-level parser. Their argument handling is added
in the following stages.

## Global options

- `--json` enables machine-readable output.
- `--help` and `-h` request command help.

## Exit codes

- `0`: success or help/version output.
- `2`: invalid command-line invocation.
- `3`: recognized command that is not implemented yet.
- Future codec failures reuse the command-specific failure categories from the
  library layer.
