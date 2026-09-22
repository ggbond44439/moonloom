# MoonLoom design

MoonLoom is split by representation boundary rather than by user-facing
feature. Each layer consumes a smaller, already-validated representation and
does not reach backward into a higher layer.

## Layers

1. `Limits` defines allocation and input boundaries.
2. `MoonLoomError` is the shared typed failure surface.
3. `varint` handles the unsigned prefix encoding used by other formats.
4. `registry` is the single source for stable multicodec numbers, names,
   categories, and Multiaddr protocol value kinds.
5. `multibase` converts bytes to and from self-describing text strings.
6. `multihash` combines a hash code, digest length, and digest.
7. `cid` combines a version, codec, and multihash.
8. `multiaddr` models protocols, typed values, and path segments before text or
   binary codecs are attached.

## Hash boundary

MoonLoom owns the multihash format and verification control flow. It does not
own cryptographic primitives. `HashProvider` receives the selected algorithm
and bytes, then returns a digest or a typed error.

The bundled SHA-2 provider delegates to MoonCrypt. This keeps format behavior
testable without mixing protocol parsing with cryptographic implementation.

## Data flow

Text to binary:

```text
CID text
  -> Multibase prefix handling
  -> CID version and codec decode
  -> Multihash decode
  -> bytes

Multiaddr text
  -> future protocol/value parser
  -> typed Multiaddr model
  -> future binary protocol codec
```

Binary to text:

```text
content bytes
  -> HashProvider
  -> Multihash
  -> CID
  -> canonical CID text

typed Multiaddr model
  -> future protocol registry metadata
  -> canonical Multiaddr text
```

## Invariants

- A decoder returns the number of bytes consumed when prefix decoding is
  allowed.
- A strict decoder rejects non-canonical encodings instead of normalizing them.
- Encoders are deterministic and use the shortest valid representation.
- Unknown registry and multihash codes remain unknown; MoonLoom never guesses
  a name or silently substitutes an algorithm.
- Multiaddr protocol metadata is generated into the codec view instead of
  maintaining a second protocol list.
- Resource limits are checked before allocation.
- Public errors carry enough context to locate the failing byte.
- CID verification is an explicit operation with an explicit provider.
- Multiaddr path values are validated before they enter a `Multiaddr` value.

## Deliberate omissions

MoonLoom does not implement IPFS, libp2p, CAR, an IPLD resolver, a blockstore,
or a network client. It produces and validates the format primitives those
systems need, leaving storage and transport to other packages.
