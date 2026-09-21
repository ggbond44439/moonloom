# Format boundaries

This document defines what MoonLoom accepts in the first milestone. It is a
contract for the code, not a list of future aspirations.

## Unsigned varint

- Encoding is unsigned LEB128 with the minimum possible number of bytes.
- The maximum value is `UInt64::MAX_VALUE`.
- The decoder rejects overlong encodings such as `80 00`.
- The decoder rejects overflow and truncation with a byte offset.
- Signed/zigzag varints are not part of this milestone.

## Multibase

The initial registry supports these prefixes:

| Prefix | Encoding | Padding |
| --- | --- | --- |
| `f` | base16 lower | no |
| `F` | base16 upper | no |
| `b` | base32 lower | no |
| `B` | base32 upper | no |
| `c` | base32 lower | yes |
| `C` | base32 upper | yes |
| `z` | base58btc | no |
| `m` | base64 | no |
| `M` | base64 | yes |
| `u` | base64url | no |
| `U` | base64url | yes |

Decoding is strict:

- Unknown prefixes are rejected.
- Mixed-case base16/base32 input is rejected.
- Invalid alphabet characters and malformed padding are rejected.
- Base64 length `mod 4 == 1` is rejected.
- Whitespace is not ignored.

## Multicodec registry

The registry is a curated subset. Codes are stable numeric identifiers and are
resolved by name or number. Unknown codes are preserved as unknown values; they
are not assigned a guessed name.

The current table covers:

- `identity`
- `cidv1`
- `sha2-256`, `sha2-512`, `sha3-256`, `sha3-512`, `blake3`
- `raw`, `dag-pb`, `dag-cbor`, `libp2p-key`
- `ip4`, `ip6`, `dns`, `dns4`, `dns6`, `dnsaddr`
- `tcp`, `udp`, `p2p`, `http`, `https`, `ws`, `wss`

The table will be expanded only from the upstream registry, with source and
version recorded in the repository.

## Limits

`Limits` bounds input length, varint width, digest size, and future Multiaddr
size. Limits are explicit parameters at parsing boundaries and are designed to
be lowered by applications that process untrusted input.

## Not implemented yet

- Multihash
- CIDv0 and CIDv1
- Multiaddr text/binary codecs
- CLI commands
- Mooncakes publication
- CAR, IPLD, blockstores, networking, and DNS resolution

Those boundaries are deliberate. MoonLoom will not claim support for a format
before its codec, tests, and documentation exist.


Registry source: `https://github.com/multiformats/multicodec/blob/master/table.csv`, checked on 2026-09-21.
