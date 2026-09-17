# Investment app changes auto-apply to the local Desktop

For any user-requested app-facing change in `D:\Dev\Investment`, including sections other than Dashboard, treat the request as authorization to apply the completed change to the user's local taskbar Desktop app unless the user explicitly asks for investigation, planning, proposal, prototype-only work, or no application.

The default completion path is:

1. Implement the approved request and run proportionate verification.
2. Integrate the tested change through the repository workflow.
3. Build the current `main` local Desktop executable without publishing an installer or external artifact.
4. Close or replace stale local app processes when needed, launch the exact executable under `D:\Dev\Investment`, and verify the requested behavior in the real window.
5. Leave the app open at the changed section so the user can inspect it.
6. If the user is dissatisfied, either make a forward correction from the applied state or revert the requested change when the user explicitly chooses a revert.

Do not describe source implementation, tests, merge, or build alone as complete when the task is meant for app use. Formal artifact publishing, external Desktop distribution, shared DB apply, Scheduler registration, secrets, permissions, and other human-gated production actions remain separately approval-gated.
