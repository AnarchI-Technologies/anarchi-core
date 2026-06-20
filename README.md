# AnarchI Core

Core primitives for AnarchI Technologies systems.

Hardcoding freedom into the systems of tomorrow.

## Purpose

AnarchI Core is the foundation layer for reusable automation, orchestration, and operator workflows. The current repository contains an early PowerShell implementation surface and is being shaped into a cleaner platform core.

## What This Repo Represents

- Deterministic command and workflow primitives.
- Local operator tooling for system assembly.
- Shared foundations that other AnarchI projects can build on.
- A public-safe view of the architecture without private CERBERUS internals.

## Current Structure

```text
.
└── anarchi_core.ps1
```

## Development Direction

The next production step is to split the current script into reviewed modules:

- `commands/` for operator entrypoints.
- `lib/` for reusable deterministic functions.
- `tests/` for fixture-backed validation.
- `docs/` for public architecture notes.

## Operating Principles

- Keep control flow inspectable.
- Prefer explicit rules over opaque automation.
- Treat AI as an escalation path, not the default engine.
- Keep private strategy, credentials, and live runtime state out of the public repo.