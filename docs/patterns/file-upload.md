# File upload integration

`CarbonFileUploader` is presentation. The application supplies a selection
control and `CarbonFileUploaderItem` rows. Carbide does not open files, receive
platform drops, validate content, transmit bytes, schedule retries, or cancel
requests. Give records stable identifiers and keys; keep the adapter and its
state outside the widget's build method.

## State and progress

Map a selected, removable file to `CarbonFileStatus.edit`. A request in flight
uses `uploading`; a successful request uses `complete`. A failure returns to
`edit` with `invalid: true`, `errorSubject` and `errorBody`. There is no error or
pending enum value. The row shows a spinner while uploading and a checkmark on
completion; `onDelete` is available in edit state. Add a separate application
remove/cancel action when other states need it.

For numeric progress, compose `CarbonProgressBar` using the adapter's bytes
sent / total bytes. Do not manufacture a percentage when the transport cannot
report one; use indeterminate progress instead. Announce meaningful state
changes through a live region rather than every byte update.

The gallery's copied example is a complete in-memory recipe. Selection adds
`demo-report.pdf`; Start upload enters uploading, each Advance upload adds
50%, Simulate failure exposes an error and Retry upload restarts. Remove file
clears the record. These are deliberate simulation actions, with no timer,
network service, native picker or real platform drop handler.

## Web selection and drops

An application can add Flutter's [`file_selector`](https://pub.dev/packages/file_selector)
plugin and call `openFiles` from the uploader button callback. Cancellation
returns no selection; leave existing rows intact. Keep `XFile` objects or
streams in the adapter, not only their names. Use their read/stream API for web
bytes; a selected browser file's path is not a desktop filesystem path.
Filters are platform-specific; configure options supported by the target.

For drag and drop, place a platform adapter around
`CarbonFileUploaderDropContainer`. Wire enter/exit to `dragOver` and route
received files through the same acceptance function as picker results. Flutter
`DragTarget` by itself accepts Flutter drag data, not operating-system file
drops. [`desktop_drop`](https://pub.dev/packages/desktop_drop) is one separately
maintained adapter with documented web and desktop support. Its `DropTarget`
provides enter, exit and completed-drop callbacks. Applications choose and test
that dependency; Carbide does not include it or imply iOS drop support.

The adapter should clear hover state after a drop, cancellation, route removal
or error. Keep an accessible selection button as an alternative to dropping.

## Mobile and desktop selection

`file_selector` documents Android, iOS, Linux, macOS, Windows and web targets.
Invoke it from an explicit user action, then convert selected files into the
same adapter records. An image-specific application may choose a camera/photo
adapter instead. Declare the permissions and platform configuration required
by that adapter; Carbide cannot supply them for the host application.

For a sandboxed macOS host, `file_selector` documents user-selected file access
entitlements. Use read-only access when that is sufficient. Do not request
broad storage or photo permissions merely to render this component. Treat
selection cancellation, denied access, and files that disappear before reading
as ordinary adapter outcomes with useful feedback.

## Validation, transport and lifetime

Client-side extension, media-type, count and size checks improve feedback. They
are not a security boundary: the receiving service must independently validate
content, size limits, authorization and storage policy. Do not trust the
filename or the picker filter as proof of file type.

Keep cancellable operations keyed by record ID. On removal or disposal, cancel
when supported and ignore completions whose record/request generation is no
longer current. Retrying creates a new request generation so an old result
cannot overwrite it. Check mounted ownership before applying UI updates. Never
start a request from build. Keep credentials and upload endpoints in the
application's transport layer.

`CarbonFileUploader.disabled` styles its labels. Also disable the supplied
button/drop container and item actions in application state; the container
does not recursively override arbitrary children.
