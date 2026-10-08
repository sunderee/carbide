# Notifications

Choosing between inline, toast, actionable, and callout notifications — and
writing messages worth interrupting people for.

> Adapted from the Carbon Design System "Notifications" pattern
> (Apache-2.0, carbon-design-system/carbon-website; see NOTICE). Guidance
> is rewritten for Carbide's API.

Three principles: notifications must be **relevant** (tied to what the user
is doing), **timely** (critical ones immediately, the rest promptly), and
**informative** (context plus a next step). Every notification you add
competes with the user's attention — when in doubt, don't.

## Status

Status is orthogonal to type; every notification carries one
(`CarbonNotificationKind`):

| Kind | Meaning | Color / icon |
|---|---|---|
| `info` | Additional information, not tied to the current action | blue, information filled |
| `success` | A task completed as expected | green, checkmark filled |
| `warning` | The action may have undesirable consequences | yellow, warning filled |
| `error` | A failure; may block until resolved | red, error filled |

Never rely on color alone — the kind icon and the title carry the status
for color-blind users and screen readers.

## Type

| Type | Carbide API | Use when | Lifetime |
|---|---|---|---|
| Inline | `CarbonInlineNotification` | Feedback about the user's *current* task, shown in context (top of a form, inside a card) | Persists until resolved or dismissed |
| Toast | `CarbonToastNotification` | Non-disruptive, system-initiated updates unrelated to the current task | Slides in; auto-dismisses (or persists if it has an action) |
| Actionable | `CarbonActionableNotification` | The user must be able to respond ("Retry", "Undo") | Persists until acted on or dismissed |
| Callout | `CarbonCallout` | Important contextual information that ships *with* the page content | Loads with the page; not dismissible, not triggered |
| Modal | `CarbonModal` (danger/acknowledgement composition) | Critical information that must block the task | Blocks until dismissed |

Decision shortcuts:

- Feedback on what the user just did, where they did it → **inline**.
- The system has news the user didn't ask for right now → **toast**.
- The message needs a button → **actionable** (an inline ghost action or a
  toast-style action).
- It isn't an event at all, just something this page must say → **callout**.
- Ignoring it would be dangerous → **modal**, sparingly.

## Writing the message

- `title`: the outcome, in a few words ("Deployment failed").
- `subtitle`: the reason and the next step ("The registry rejected the
  image. Check the credentials and retry.").
- Time-stamp toasts when the feed can back up (`caption`).
- Error notifications name what failed *and* how to recover; never a bare
  "An error occurred".

## Example

```dart
// Inline, at the top of the form it concerns:
CarbonInlineNotification(
  kind: CarbonNotificationKind.error,
  title: 'Account not created',
  subtitle: 'Fix the two fields marked below and resubmit.',
  onClose: _dismiss,
)

// Actionable, when the user can respond directly:
CarbonActionableNotification(
  kind: CarbonNotificationKind.warning,
  title: 'Connection lost',
  subtitle: 'Changes are no longer being saved.',
  actionLabel: 'Reconnect',
  onAction: _reconnect,
  onClose: _dismiss,
)
```

## Placement and stacking

Toasts anchor to the top trailing corner of the viewport and stack
newest-first; keep at most a handful on screen and drop the oldest. Inline
notifications sit immediately above the content they concern. Their width
is capped at 288 px below `md`, 608 px from `md`, 736 px from `lg`, and
832 px from `max`. Toasts use 288 px, growing to 352 px from `max`.
These shared Carbon breakpoints use viewport width (`MediaQuery.size`);
without a viewport, the available width is used. Parent constraints always
cap the result. Action buttons move below the message on small viewports
and in narrow content columns. Their height grows with scaled or wrapped text.

## Accessibility

| Variant | Announcement | Focus policy |
|---|---|---|
| Inline | `status` (polite), or `alert` (assertive) for errors on web | Keeps current focus |
| Toast | Same severity policy; includes the caption | Keeps current focus |
| Actionable | Same severity policy; includes the optional action's label | Keeps focus; action and close controls participate in traversal |
| Callout | Static page content, no live region | Optional action participates in traversal |

Web notifications use the roles' [implicit live-region urgency](https://www.w3.org/TR/wai-aria-1.2/#alert)
(`status` is [polite](https://www.w3.org/TR/wai-aria-1.2/#status)). They omit
Flutter's additional live-region flag, whose web handler queues a separate
polite announcement. Native notifications retain that flag, with urgency
and timing controlled by the platform accessibility service: Flutter does
not expose equivalent per-node native politeness. Its explicit announcement
API also [supports assertiveness only on web](https://api.flutter.dev/flutter/semantics/SemanticsService/sendAnnouncement.html).

Actionable notifications deliberately remain nonmodal: Retry or Undo can be
offered without moving or trapping focus and interrupting the current task.
This differs from Carbon React's default `alertdialog`. Use a modal dialog
when the user must respond before work can continue. Callouts never announce
updates automatically. Auto-dismissing toasts must never carry actions the
user could miss; an actionable message persists.

## Related

- [Forms pattern](forms.md) — pairing inline notifications with field errors
- [Loading pattern](loading.md) — when a wait, not a message, is the answer
- Gallery: Notification page
