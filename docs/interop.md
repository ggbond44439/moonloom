# Interoperability and hardening

MoonLoom uses externally defined vectors wherever possible. Tests do not rely
only on self-generated round trips.

## Sources

- RFC 4648: base16, base32, and base64 alphabets and padding.
- Multibase specification: prefix and canonical text behavior.
- Multicodec registry table: numeric protocol and codec identifiers.
- Multihash specification: code, digest length, and digest layout.
- CID specification: CIDv0 and CIDv1 binary layouts and canonical text.
- Multiaddr specification: protocol codes, binary value widths, and IPv6 text.

## Pinned vectors

Examples covered by `interop_test.mbt`:

| Format | Input | Expected |
| --- | --- | --- |
| Multibase base32 | `hello` | `bnbswy3dp` |
| Multibase base64 | `hello` | `maGVsbG8` |
| Multibase base58btc | `hello` | `zCn8eVZg` |
| SHA-256 | `hello` | `2cf24dba...938b9824` |
| Multihash text | `hello` | `zQmRN6wdp1S2A5EtjW9A3M1vKSBuQQGcgvuhoMUoEz4iiT5` |
| CIDv1 raw empty | empty bytes | `bafkreihdwdcefgh4dqkjv67uzcmw7ojee6xedzdetojuzjevtenxquvyku` |
| CIDv1 dag-pb empty | empty bytes | `bafybeihdwdcefgh4dqkjv67uzcmw7ojee6xedzdetojuzjevtenxquvyku` |
| CIDv0 empty | empty bytes | `QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n` |
| Multiaddr IPv4/TCP | `/ip4/127.0.0.1/tcp/8080` | `047f000001061f90` |
| Multiaddr IPv6/UDP | `/ip6/::1/udp/53` | `290000000000000000000000000000000191020035` |

## Hardening tests

`hardening_test.mbt` adds:

- deterministic generated-byte inputs across all binary decoders;
- no-panic checks for malformed varint, Multihash, CID, and Multiaddr input;
- round trips across generated varint values;
- truncation checks at protocol and value boundaries.

These tests complement, but do not replace, future differential testing with
other Multiformats implementations.
