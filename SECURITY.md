# Security

MoonLoom is a parser and encoder for untrusted external data. Reports should
identify the affected format, input bytes, expected behavior, and observed
behavior.

The current milestone rejects truncation, overflow, non-canonical varints,
unknown Multibase prefixes, invalid alphabets, malformed padding, digest size
mismatches, CID trailing bytes, and content hash mismatches. Resource limits
are part of the public API.

MoonLoom does not implement cryptographic primitives. SHA-2 is delegated to
MoonCrypt through a provider boundary. The parser never silently substitutes a
different hash algorithm.

MoonLoom does not implement networking, a blockstore, or an IPFS node. Do not
treat it as a security boundary for those systems.
