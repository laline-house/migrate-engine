# Migration Engine

Reusable engine for legacy system archival and audit reporting.

This repository contains only reusable assets:
- schemas (DDL)
- scripts (load/transform/validate)
- templates (runbook, handover, compliance)
- optional Metabase templates

It does **not** contain client data, extracts, logs, or credentials.

## How it’s used

On a client environment we keep two folders side-by-side:

C:\migration\
- engine\        (clone of this repo)
- workspace\     (client-specific runtime folder: extracts/logs/handover)

The engine reads configuration from a client `.env` inside the workspace.

## Folder layout

- `docs/templates/` – templates for handover, compliance, runbook
- `schemas/` – database schemas and DDL
- `scripts/` – loaders, transforms, validators
- `metabase/templates/` – optional BI collection templates
- `config/examples/` – safe example configs (no secrets)

## Rules

- Never commit `extracts/`, `logs/`, `outputs/`, `.env`
- Client data lives only in the workspace folder (outside git)

## Versioning

Tag releases when delivering to clients, e.g.:
- `v1.0.0`
