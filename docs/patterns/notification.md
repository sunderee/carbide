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
notifications span the content column they concern — full width of the
form or card, immediately above it.

## Accessibility

Carbide notifications expose their kind and text to assistive technology.
Toasts announce politely; error notifications assertively. Auto-dismissing
toasts must never carry actions the user could miss — if it has a button,
it persists.

## Related

- [Forms pattern](forms.md) — pairing inline notifications with field errors
- [Loading pattern](loading.md) — when a wait, not a message, is the answer
- Gallery: Notification page
