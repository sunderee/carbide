# Progress indicators

`CarbonProgressIndicator` keeps the current step and selection policy with the
caller. Use `interactive: true` and `onStepSelected` for pointer, Enter/Space
and accessibility activation. Disabled steps remain inert. Each step retains
its complete name, progress state and optional supporting label in semantics.

Horizontal steps use Carbon v11.118.0's 128 px grid: a full leading 2 px line,
a 16 px glyph 10 px below the top, and an 88 px one-line label beside the glyph.
Complete and current steps fill their leading line. Labels and supporting
text use ellipsis within the step; accessible names and hints retain the full
text. Constrained hosts scroll horizontally instead of compressing labels.
Tab traversal reveals enabled steps as it moves through the scroll view.

Vertical steps have a 58 px minimum, a full-height 1 px leading line, and
wrapped labels within 160 px. Taller text and supporting labels grow the step;
text scaling stays at the requested system scale. Both orientations follow
logical start/end direction and retain the existing invalid/disabled treatment.
The indicator has no animated transition, including under reduced motion.

```dart
CarbonProgressIndicator(
  currentIndex: currentStep,
  interactive: true,
  onStepSelected: selectStep,
  steps: const <CarbonProgressStep>[
    CarbonProgressStep(label: 'Account'),
    CarbonProgressStep(label: 'Details', secondaryLabel: 'Optional'),
    CarbonProgressStep(label: 'Review'),
  ],
)
```

The Flutter band reserves space for supporting text. Carbon's horizontal CSS
positions that text outside its 28.3 px list box; reserving its height here
keeps the following application content clear. The curated default-story
comparison records that framing difference. It does not establish pixel parity.
For touch-heavy or very narrow flows, callers can choose `vertical: true` to
show every step without horizontal scrolling.
