# Project Context & Agent Instructions

This document is the single source of truth for the `flutter-notion` project. All AI agents MUST read this document before planning or executing any changes in this repository.

## 1. Project Snapshot

- **Name:** flutter-notion
- **Type:** a flutter django notion clone
- **Target Scale/Users:** 1 admins, 1-2 active users. Low traffic. NOT mass-scale or enterprise production. Rather a school demo project.
- **Platform/Environment:** cross platform with flutter android as priority.
- **Complexity Goal:** Favor extreme simplicity and readability over premature optimization.

## 2. Tech Stack & Dependencies

Agents must strictly use the following stack. **DO NOT** introduce new major dependencies, frameworks, or libraries without explicit user approval.

- **Framework/UI:** flutter
- **Database/Storage:** sqlite
- **Styling/UI Lib:** flutter
- **Other Key Tools:** django in backend

## 3. Scope Boundaries

Agents must strictly adhere to these boundaries to prevent scope creep:

- **MUST DO (MVP Core):** Block-Based Document Editor

This is the heart of Notion. Every piece of content is a block — text, heading, bullet, checkbox, image, code, divider — and each block is individually manipulable. You need:

    Create block on Enter, delete on Backspace (when empty)

    Reorder blocks via drag-and-drop

    Convert block type (e.g., / slash command menu)

    Inline formatting: bold, italic, code, strikethrough

Page & Hierarchy System

Notion is essentially a tree of pages. Core data model needs:

    Pages that contain blocks

    Infinite nested child pages (a page block that opens as a new document)

    Sidebar showing the page tree, collapsible

    Page title + emoji/icon per page

Persistence & Auth

Without this nothing survives. Minimum viable stack for Flutter:

    Firebase Firestore or Supabase — real-time, easy Flutter SDKs

    Auth (Google Sign-In or email/password via Firebase Auth)

    Auto-save on every block edit (debounced)

Sidebar Navigation

The collapsible left sidebar is core UX:

    Expandable page tree

    "New Page" button

    Trash/soft-delete section

    Search shortcut (Ctrl+P style quick find)

- **OUT OF SCOPE (Do Not Build):** "Complex auth", "Microservices", "Cross-platform support", "High-availability clustering"

## 4. Coding Style & Simplicity Mandates

1. **Readable Over Clever:** Write dumb, obvious code. Avoid complex abstractions, deeply nested logic, or "clever" one-liners.
2. **Standard Patterns:** Match the existing codebase style. If starting from scratch, use the most standard, idiomatic patterns for the chosen framework.
3. **No Premature Scaling:** We are building for 2 users. Do not implement complex caching, message queues, or distributed systems unless explicitly required in the Scope Boundaries.
4. **Error Handling:** Fail fast and log clearly. Do not swallow errors.

## 5. Phased Execution & Planning Workflow

Agents must follow this exact workflow when tackling a task:

### Step 1: Understand & Plan (Read-Only)

- Read this `agent.md` file.
- Use read/search tools (`read`, `glob`, `grep`) to understand the current state of the codebase.
- Formulate a clear, step-by-step plan.
- **STOP and present the plan to the user for approval before writing any code.**

### Step 2: Phase-by-Phase Implementation

- Execute the approved plan one phase at a time.
- **Do not jump ahead.** Complete Phase 1, verify it works, and commit (if requested) before starting Phase 2.
- **Example Build Order:**
  1. _Phase 1:_ Data models and basic scaffolding.
  2. _Phase 2:_ Core logic / API routes.
  3. _Phase 3:_ UI / CLI integration.
  4. _Phase 4:_ Edge cases, error handling, and testing.

### Step 3: Verify & Test

- After implementing a phase, run the designated test commands
