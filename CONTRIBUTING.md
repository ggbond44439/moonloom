# Contributing

MoonLoom values small, reviewable changes with protocol evidence.

1. Cite the specification or upstream registry entry for format changes.
2. Add a known-vector test for every new codec.
3. Add malformed-input tests for every parser.
4. Use typed errors; do not make invalid input panic.
5. Keep registry codes centralized.
6. Run `moon fmt`, `moon check`, and `moon test` before submitting.

No cryptographic primitive should be added to MoonLoom directly. Hash
algorithms belong behind a provider boundary and should come from an existing,
reviewed implementation.
