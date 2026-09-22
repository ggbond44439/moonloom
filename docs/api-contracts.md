# Public API contracts

This document records the stable conventions that new MoonLoom formats and CLI
commands must follow.

## Naming

- `parse` accepts owned protocol text and returns the decoded value.
- `decode` accepts binary bytes and returns the value plus consumed length when
  trailing data is meaningful.
- `to_*` returns canonical output unless the function name explicitly selects a
  representation.
- `from_*` is a constructor alias when the input identifies a complete value.
- `verify` checks content against a decoded value and returns `Unit` on match.

## Construction

- Constructors validate resource limits and structural invariants.
- A constructor never fabricates a substitute algorithm or codec.
- Known hash algorithms enforce their exact digest size.
- Unknown codes may be preserved for inspection, but cannot be verified without
  an explicit provider.

## Errors

`MoonLoomError` is the shared external error type. Errors must distinguish:

- invalid user input
- unsupported but well-formed algorithms
- length or resource-limit violations
- content mismatches
- unknown codecs

Offsets are byte offsets unless the error explicitly names a text position.

## Limits

`Limits` is passed explicitly at every untrusted parsing or verification
boundary. New formats must add a focused check helper rather than reading the
raw fields directly.

## Extension seams

- `HashProvider` decouples Multihash and CID verification from cryptographic
  implementations.
- `Base` and `supported_bases` define the text-encoding registry.
- `multicodec_info`, `multicodec_code`, `protocol_info`, and `CodecCategory`
  define the shared numeric registry.
- Multiaddr path values are constructed through `PathSegment::new` so invalid
  protocol/value combinations cannot enter the typed model.
- Future Multiaddr protocol codecs must consume registry metadata instead of
  hard-coding protocol names in parser branches.
- Binary protocol layers must use `WireReader` and `WireWriter` instead of
  maintaining private cursor or append logic.

## Compatibility

Additive API changes are preferred. Renaming or removing a public function
requires a migration note in `CHANGELOG.md` and an update to the generated
`.mbti` interface.
