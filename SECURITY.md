# Security

MoonLoom is a parser and encoder for untrusted external data. Reports should
identify the affected format, input bytes, expected behavior, and observed
behavior.

The current milestone rejects truncation, overflow, non-canonical varints,
unknown Multibase prefixes, invalid alphabets, and malformed padding. Resource
limits are part of the public API.

MoonLoom does not currently implement cryptographic primitives, networking, or
a blockstore. Do not treat it as a security boundary for those systems.
