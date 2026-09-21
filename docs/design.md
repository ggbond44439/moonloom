# MoonLoom design

MoonLoom is split by representation boundary rather than by user-facing
feature. Each layer consumes a smaller, already-validated representation and
does not reach backward into a higher layer.

## Layers

1. `Limits` defines allocation and input boundaries.
2. `MoonLoomError` is the shared typed failure surface.
3. `varint` handles the unsigned prefix encoding used by other formats.
4. `registry` maps stable multicodec numbers to reviewed names and categories.
5. `multibase` converts bytes to and from self-describing text strings.
6. Future `multihash`, `cid`, and `multiaddr` packages compose those layers.

## Data flow

Text to binary:

```text
Multibase text
  -> prefix lookup
  -> alphabet and padding validation
  -> bytes
  -> future Multihash/CID/Multiaddr decoder
```

Binary to text:

```text
canonical bytes
  -> future Multihash/CID/Multiaddr encoder
  -> bytes
  -> selected Multibase encoder
  -> prefixed text
```

## Invariants

- A decoder returns the number of bytes consumed when prefix decoding is
  allowed.
- A strict decoder rejects non-canonical encodings instead of normalizing them.
- Encoders are deterministic and use the shortest valid representation.
- Unknown registry codes remain unknown; MoonLoom never guesses a name.
- Resource limits are checked before allocation.
- Public errors carry enough context to locate the failing byte.

## Deliberate omissions

MoonLoom does not implement IPFS, libp2p, CAR, an IPLD resolver, a blockstore,
or a network client. It produces and validates the format primitives those
systems need, leaving storage and transport to other packages.
