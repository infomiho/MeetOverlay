# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Layout

This is a single-context repo.

## Before exploring, read these

- `CONTEXT.md` at the repo root
- `docs/adr/`

If any of these files do not exist, proceed silently. Do not flag their absence or suggest creating them upfront.

## Use the glossary's vocabulary

When output names a domain concept in an issue title, refactor proposal, hypothesis, or test name, use the term as defined in `CONTEXT.md` when it exists.

If the concept you need is not in the glossary yet, note the gap for `/grill-with-docs` instead of inventing new project language.

## Flag ADR conflicts

If output contradicts an existing ADR, surface it explicitly rather than silently overriding it.
