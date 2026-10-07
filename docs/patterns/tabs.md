# Tabs, focus and overflow

`CarbonTabs` and `CarbonTabsVertical` use the same scroll metrics, edge tracking
and reveal coordinator. Horizontal strips scroll when their content exceeds
the available width; controls point toward the first/last tab and disable at
the corresponding extents. Narrow strips cap individual tab widths and retain
the complete accessible label when visible text is ellipsized.

`activation: CarbonTabActivationMode.automatic` retains the original default:
navigation focuses and selects the destination. Manual activation moves focus
with arrows or Home/End, while Enter or Space selects that focused tab. Pointer
activation selects in either mode. Disabled tabs are skipped. Controlled
selection still belongs to the caller; if it ignores a change callback, the
focused index can advance while the selected panel stays unchanged.

Horizontal arrows follow visual chronology: Right advances in LTR and Left
advances in RTL. Vertical tabs use Up/Down and do not react to Left/Right.
Home/End reach the first/last enabled tab. The currently active tab provides
the tab list's keyboard traversal stop; other tabs remain available to roving
navigation and accessibility focus. Scroll controls are outside ordinary Tab
traversal because arrow navigation reaches the tabs directly. They retain
named pointer and accessibility actions in the Flutter port; Carbon's web
implementation hides those controls from its accessibility tree.

Changing selection or focus reveals its tab, and viewport changes reconcile
visibility. Scrolling with the edge controls does not select a tab or snap the
viewport back to the previous selection. Programmatic selection changes keep
focus with the new selection when focus is already inside the tabs, and
removing tabs clamps the state without reporting a user change. Independent
panel content remains available below or beside the list.

Programmatic reveals and scroll controls use the existing Carbon motion
resolver. Reduced motion jumps directly to the destination. Enabling it while
a programmatic scroll is active completes that scroll immediately. Vertical
fades retain their half-row edge threshold and selection reveal offset.

The supported Flutter roles are `SemanticsRole.tabBar`, `tab` and `tabPanel`.
Each tab identifies the rendered panel through `controlsNodes`; visible labels
remain available once, and a dismiss control keeps its own action/name. Use
`tabListLabel`, `scrollBackwardLabel` and `scrollForwardLabel` for localized
accessible names. The gallery exposes many tabs, style, orientation and manual
activation for comparison. These roles and native DOM relationships are
verified separately from keyboard, clipping and callback behavior.

On Flutter 3.47.6 web, a small semantics adapter clears stale native tab stops
after roving focus changes and exposes the disabled state omitted by the
engine's tab role. Flutter continues to own focus actions, selection and panel
relationships. Other platforms use the framework semantics directly.
