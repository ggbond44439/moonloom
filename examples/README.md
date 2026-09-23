# Examples

Run each example from the repository root:

```text
moon run examples/artifact_cid
moon run examples/multiaddr_normalize
moon run examples/cross_language_fixture
```

## artifact_cid

Creates a CIDv1 for a byte string, prints the canonical CID, and verifies the
content.

## multiaddr_normalize

Parses an uncompressed IPv6 Multiaddr, emits the canonical RFC 5952 form, and
shows its deterministic binary encoding.

## cross_language_fixture

Creates a Multihash and CID fixture together with the binary CID encoding so the
values can be compared with another Multiformats implementation.
