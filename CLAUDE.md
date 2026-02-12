## Workflow

Wait for the user to finish describing all issues before starting investigation or implementation. Do not begin exploring the codebase mid-list.

## Code Quality

After making UI or JavaScript changes, always verify the app loads without blank screen errors by checking for syntax errors and runtime exceptions before committing.

When removing a feature, audit ALL references: UI components, localStorage keys, event handlers, and related logic. Do a grep for the feature name before marking removal complete.

## Debugging

When fixing bugs, identify the root cause before applying fixes. Avoid quick patches like setTimeout or surface-level workarounds — trace the actual problem first.

## Deployment

This project deploys via GitHub Pages. Always verify the build output directory is configured correctly (not serving source). Check deployment config before and after structural changes.
