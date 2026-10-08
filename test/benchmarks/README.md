# Performance measurements

These harnesses are opt-in measurements, separate from the deterministic
`*_test.dart` regression suites. Run from the repository root with the same
Flutter SDK used by the package. Timing values are observations, not CI limits.

## Icon and pictogram path cache

```sh
flutter test --enable-vmservice test/benchmarks/icon_cache_benchmark.dart \
  --dart-define=CACHE_FAMILY=icons --dart-define=CACHE_COUNT=100
```

Repeat with `CACHE_COUNT=1000` and `2775`, then with
`CACHE_FAMILY=pictograms` at `100`, `1000` and `1576`. These full-registry counts
are for Carbon v11.118.0; use the current registry lengths after a reference
update. Run each case in three fresh processes, without concurrent benchmarks,
and record the medians in the PR. `CACHE-MEASURE` lines are JSON.

The harness renders **all artwork variants** of the requested definitions with
the production `CarbonIconPainter`, disposing recorded pictures immediately.
Before the baseline it traverses the const registry, warms the parser with
twenty shapes and initializes the cache with one separate dummy shape. The
dummy's retained size is subtracted from the result. It asserts that the cache
grows by exactly the number of distinct value-equal shapes rendered.

Two GC requests, separated by 50ms for finalizers, precede each snapshot. The
VM service reports the cache map's retained **Dart heap** size, isolate external
allocation accounting, and whole-process RSS. These are different measurements:

- Retained Dart bytes describe the map and reachable wrappers, not native
  vector geometry.
- External accounting is what the VM charges to native objects; it is not an
  exact measurement of all engine/Skia path allocations.
- RSS includes native allocations, JIT code, VM heap capacity and allocator
  retention. Its before/after difference cannot be attributed solely to paths.

The benchmark reports a first production paint, a mean of ten cached paints,
and three uncached parser passes. Parser-only reparse timing excludes applying
the shape's fill rule/transform, recording a canvas and rasterization. Paint
timing includes recording/disposal, but excludes rasterization and display.
This is a native debug/JIT benchmark, not a release frame-time claim or a web
memory measurement.

The VM diagnostic `_getRetainedSize` and private cache-field inspection were
verified against Dart 3.13.5. They are measurement tooling, not product API;
check the diagnostic protocol when changing SDK versions. No test hook, cache
mutation, additional package dependency or runtime telemetry is introduced.

For the resulting cache lifetime policy, see
[architecture](../../docs/ARCHITECTURE.md#icon-path-cache-policy).
