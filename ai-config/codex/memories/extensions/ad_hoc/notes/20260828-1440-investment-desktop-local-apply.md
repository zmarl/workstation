# Investment Desktop UI completion boundary

For `D:\Dev\Investment` changes that the user is expected to use through the taskbar Desktop app, source implementation, tests, and merge are not sufficient completion.

After the change lands on current `main`, complete the local single-PC application path by:

1. Build the current main Desktop executable with the existing local release/no-bundle path.
2. Close any stale registered or cached `Investment Control Tower` process that would intercept single-instance launch.
3. Launch the exact executable under `D:\Dev\Investment\desktop\src-tauri\target\release\investment-desktop.exe`.
4. Verify the requested behavior in the real Desktop window and confirm the visible build timestamp is current.

Keep formal artifact publishing, update-channel changes, shared DB apply, Scheduler registration, and external Desktop distribution approval-gated. Report a task as incomplete if only source/merge is finished while the taskbar app still shows the old UI.
