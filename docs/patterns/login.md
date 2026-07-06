# Login

How to build a sign-in flow that gets users into the product quickly and
recovers gracefully when credentials fail.

> Adapted from the Carbon Design System "Login" pattern (Apache-2.0,
> carbon-design-system/carbon-website; see NOTICE). Guidance is rewritten
> for Carbide's API.

## The pieces

| Role | Carbide API |
|---|---|
| User ID entry | `CarbonTextInput` (`keyboardType: TextInputType.emailAddress`) |
| Password entry | `CarbonPasswordInput` (built-in show/hide toggle) |
| Fluid (contained) styling | wrap the form in `CarbonFluidForm` |
| Continue / Log in | `CarbonButton` |
| Create account, forgot password | `CarbonLink` |
| Remember ID | `CarbonCheckbox` |
| Server-side errors | `CarbonInlineNotification` (`CarbonNotificationKind.error`) |
| Submission in flight | `CarbonInlineLoading` |

## Anatomy

Title first ("Log in", optionally with the product name), then the user
ID field, then the primary button. Optional elements — a create-account
`CarbonLink` near the title, a "Forgot password?" link by the password
field, a `CarbonCheckbox` labelled precisely ("Remember ID", not
"Remember me"), and alternative login buttons — sit around that spine
without displacing it.

## Progressive authentication

Ask for the user ID alone with a "Continue" button. The system then
routes to the right flow — the organization's SSO, or a password step —
instead of making the user pick from options. On the password step,
provide a way back to correct a mistyped ID.

If the backend cannot distinguish routes, present alternative login
buttons up front, but keep the hierarchy honest: the primary button
stays directly under the ID input, and alternates go *below* it — never
between the input and the primary action, and never above the form.

## Errors and validation

- Client-side: validate when a field loses focus or the action button is
  pressed. Set `invalid: true` with an `invalidText` such as "Email is
  required" or "Enter a valid email address". Clear the error as soon as
  the field is corrected.
- Server-side: on a failed submit, clear the password field, return
  focus to the user ID input, and show a `CarbonInlineNotification`
  above the form. Stack notifications if several errors apply.
- Do not reveal whether an *account* exists before the full credential
  pair is submitted, and use one generic message for both wrong ID and
  wrong password ("Incorrect email or password. Try again.") so valid
  addresses cannot be harvested.

## Design and layout

- *Fluid* — wrap the fields in `CarbonFluidForm` inside a raised
  container. The contained look suits a floating sign-in card; keep the
  card's width fixed between the ID and password steps so nothing jumps.
- *Default* — plain fields directly on the page or in a side-aligned
  panel. Required when alternate login buttons must sit close to the
  input, since fluid fields join into one surface.
- *Centered layout* — the form alone on a quiet background; users came
  to log in, so marketing content only distracts.
- *Split screen* — form on one side, minimal product content on the
  other. Keep every login-related action (create account, SSO) inside
  the form region; users do not look for them in marketing content.

## Example

```dart
CarbonFluidForm(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      CarbonTextInput(
        labelText: 'Email',
        keyboardType: TextInputType.emailAddress,
        invalid: _emailError != null,
        invalidText: _emailError,
        onChanged: _onEmailChanged,
      ),
      CarbonPasswordInput(
        labelText: 'Password',
        invalid: _passwordError != null,
        invalidText: _passwordError,
      ),
      const SizedBox(height: CarbonSpacing.spacing06),
      CarbonButton(label: 'Continue', onPressed: _continue),
      const SizedBox(height: CarbonSpacing.spacing05),
      CarbonLink(label: 'Forgot password?', onPressed: _forgot),
    ],
  ),
)
```

## Accessibility

The whole flow must work with the keyboard alone: `Tab` through fields,
links, and buttons in visual order. In a split-screen layout, keep the
login form early in the widget tree so screen readers reach the inputs
without wading through side content.

## Related

- [Forms pattern](forms.md) — labels, validation, button placement
- [Notifications pattern](notification.md) — server-error surfaces
- [Loading pattern](loading.md) — submission-in-flight states
