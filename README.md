# MoonLoom

MoonLoom is a pure MoonBit toolkit for self-describing content addressing. It
brings Multibase, Multicodec, Multihash, CID, and Multiaddr into one small,
strict, deterministic library.

MoonLoom is not a full IPFS implementation. It focuses on the format layer:
creating canonical identifiers, converting between text and bytes, validating
input, and preserving interoperability with the Multiformats ecosystem.

## Features

- Canonical unsigned varint encoding and strict decoding.
- Multibase for base16, base32, base58btc, base64, and URL-safe base64.
- One registry for CID, hash, content format, and Multiaddr protocol metadata.
- Multihash with `identity`, `sha2-256`, and `sha2-512`.
- CIDv0 and CIDv1 creation, parsing, canonical text, and verification.
- Typed Multiaddr model, strict text parser, binary codec, and RFC 5952 IPv6
  canonical text.
- Reusable bounded `WireReader` and `WireWriter` primitives.
- Typed errors, byte offsets, and configurable resource limits.
- Multibase, Multihash, CID, and Multiaddr CLI commands.
- wasm, wasm-gc, JS, and Native target checking.

## Install

```text
moon add ggbond44439/moonloom@0.1.1
```

In another MoonBit package:

```text
import {
  "ggbond44439/moonloom" @moonloom,
}
```

## Quick start

```moonbit
let text = @moonloom.multibase_encode(@moonloom.Base32, b"hello")
assert_eq(text, Ok("bnbswy3dp"))

let provider = @moonloom.sha2_provider()
let cid = match @moonloom.cid_from_content(
  @moonloom.RAW_CODEC,
  @moonloom.Sha2_256,
  b"hello",
  provider,
  @moonloom.Limits::default(),
) {
  Ok(value) => value
  Err(err) => fail(err.to_string())
}

assert_eq(
  cid.to_text(),
  Ok("bafkreibm6jg3ux5qumhcn2b3flc3tyu6dmlb4xa7u5bf44yegnrjhc4yeq"),
)
assert_eq(
  cid.verify(b"hello", provider, @moonloom.Limits::default()),
  Ok(()),
)
```

## CLI

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

Run the local CLI with:

```text
moon run cmd/main -- version
moon run cmd/main -- cid encode hello
```

## Examples

```text
moon run examples/artifact_cid
moon run examples/multiaddr_normalize
moon run examples/cross_language_fixture
```

## Standards

- RFC 4648 base encodings
- Multiformats Multibase, Multicodec, Multihash, CID, and Multiaddr
- RFC 5952 IPv6 canonical text
- SHA-2 through the Apache-2.0 MoonCrypt package

## Build and test

```text
moon check --target all
moon test --target all
moon build
moon package --list
```

## Status

MoonLoom `0.1.1` is the format-core release for the 2026 September MoonBit
Hackathon. The library, CLI, examples, interoperability vectors, and CI matrix
are complete for the scoped formats.

## License

Apache-2.0.

