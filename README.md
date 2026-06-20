# AnarchI Core

Safe deterministic core primitives for AnarchI Technologies operator workflows.

Hardcoding freedom into the systems of tomorrow.

## Purpose

AnarchI Core is the public-safe foundation for local operator decisions: target normalization, risk gating, dry-run defaults, and explicit execution boundaries.

## What Changed

- Removed privileged system mutation, elevation, pagefile, process-cull, and browser-launch behavior from the public repo.
- Rebuilt the core as a dry-run-first PowerShell policy surface.
- Added deterministic target and risk gates.
- Added tests covering baseline, stricter, and adversarial constraints.

## Verify

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests\anarchi_core.tests.ps1
```

## Public Safety

This repo must not contain destructive system automation, credentials, private runtime state, or unreleased CERBERUS decision chains. Write-capable workflows belong behind reviewed gates and dry-run defaults.
