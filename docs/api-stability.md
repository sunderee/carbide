# Public API stability

Import `package:carbide/carbide.dart`. Its exports are the supported API.
Importing a declaration directly from `src/` does not make it public. All
exports have an explicit classification in `tool/public_api_policy.json`;
CI rejects an added or removed export without a policy update.

**Stable** APIs include the main widgets, tokens, value types and configuration
enums. **Advanced** APIs are supported lower-level building blocks for custom
composition or artwork. Advanced describes the intended audience, not an
exemption from compatibility review. Their dartdocs carry an Advanced API
marker, checked beside each declaration.

| Surface | Classification | Guidance |
| --- | --- | --- |
| `CarbonIcon`, `CarbonIcons`, `CarbonPictogram`, `CarbonPictograms` | Stable | Prefer generated artwork constants and the display widgets. |
| `CarbonIconData`, `CarbonIconArtwork`, `CarbonIconShape` | Advanced | Custom artwork construction exposes view boxes, shapes and per-size artwork. Treat generated constant data as immutable. |
| `CarbonIconPainter` | Advanced | Use only when integrating artwork into your own paint pass. Path parsing and cache implementation are internal details. |
| `CarbonListBox` and its exported menu/selection building blocks and formatter | Advanced | Shared chrome for custom pickers. The application owns editing, selection, focus and overlays; prefer Dropdown, ComboBox, MultiSelect or Select for complete controls. |
| `CarbonMenu` and its exported item widgets | Stable | Standalone menu composition is supported; the gallery Menu recipe shows controlled selections and actions. |
| `TagSurface` | Internal | Hidden from the barrel in 0.5.0. Use CarbonTag, CarbonDismissibleTag, CarbonSelectableTag or CarbonOperationalTag. |
| `ScrollIntoView` | Internal | Shared option-reveal implementation, renamed from the unexported CarbonScrollIntoView. No consumer import is needed. |

## Compatibility before 1.0

For `0.x.y`, patch releases preserve supported API signatures and documented
behavior. An intentional incompatible API change belongs in the next minor
release and includes a changelog entry and migration guidance. Additive changes
and corrected bugs still need tests and a clear description of behavior.
Advanced APIs follow this same rule; changes to renderer or picker internals do
not automatically authorize incompatible changes to exported constructors.

Deprecations name the replacement and give consumers a migration window.
Generated names and artwork can change on an upstream update; review removals
as API changes, not merely regeneration noise. Upstream React feature flags or
preview names do not silently change Carbide's compatibility promise.

The 0.5.0 export audit removes the accidentally reachable TagSurface building
block. The named Carbon tag widgets remain the supported entry points. No
public menu, picker or artwork type is removed by this audit. A direct `src/`
import can still access shared Dart implementation classes; that bypasses the
supported barrel and carries no stability commitment.
