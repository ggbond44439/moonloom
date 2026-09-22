# CLI

The `moonloom` executable is a thin process wrapper around the reusable `cli`
package. Command parsing and rendering are testable without process I/O.

## Current commands

```text
moonloom --help
moonloom version

moonloom multibase encode [--base <name>] <text>
moonloom multibase decode <multibase-text>

moonloom multihash digest [--algorithm sha2-256|sha2-512] <text>
moonloom multihash inspect <multibase-multihash>
moonloom multihash verify <multibase-multihash> <text>

moonloom cid encode [--version 0|1] [--codec <name>] [--algorithm <name>] <text>
moonloom cid decode <cid>
moonloom cid verify <cid> <text>

moonloom multiaddr parse <text>
moonloom multiaddr encode <text>
moonloom multiaddr decode [--format base64|hex] <data>
```

## Global options

- `--json` emits machine-readable output.
- `--help` and `-h` request command help.

Binary values in JSON output are represented as base64. This avoids lossy text
conversion and keeps machine output stable.

## Exit codes

- `0`: success or help/version output.
- `1`: codec, verification, or content mismatch failure.
- `2`: invalid command-line invocation.
- `3`: recognized command that is not implemented yet.
