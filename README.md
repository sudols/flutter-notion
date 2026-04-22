# Flutter + Django Notion Clone (Backend MVP)

This repository contains the core Django backend for a simplified Notion clone.

Scope for this milestone:
- 2-user max demo environment
- Simple and readable implementation
- Core features only (auth, workspaces, pages, blocks, sharing)

## Tech Stack

- Django
- Django REST Framework
- Simple JWT
- SQLite

## Setup

```bash
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/python manage.py migrate
```

## Run Server

```bash
.venv/bin/python manage.py runserver
```

API base URL: `http://127.0.0.1:8000/api/`

## Seed Demo Data

```bash
.venv/bin/python manage.py seed_demo
```

Creates two users and a sample workspace/page tree:
- `alice / password123`
- `bob / password123`

## API Endpoints

Auth:
- `POST /api/auth/register/`
- `POST /api/auth/login/`
- `POST /api/auth/refresh/`
- `GET /api/auth/me/`

Workspaces:
- `GET /api/workspaces/`
- `POST /api/workspaces/`
- `GET /api/workspaces/{id}/`
- `PATCH /api/workspaces/{id}/`
- `DELETE /api/workspaces/{id}/`
- `POST /api/workspaces/{id}/share/`

Pages:
- `GET /api/pages/?workspace={id}&parent={id|null}&search=keyword&include_archived=true`
- `POST /api/pages/`
- `GET /api/pages/{id}/`
- `PATCH /api/pages/{id}/`
- `DELETE /api/pages/{id}/`
- `POST /api/pages/{id}/archive/`
- `POST /api/pages/{id}/restore/`
- `POST /api/pages/{id}/share/`

Blocks:
- `GET /api/blocks/?page={id}`
- `POST /api/blocks/`
- `PATCH /api/blocks/{id}/`
- `DELETE /api/blocks/{id}/`
- `POST /api/blocks/reorder/`

## Permissions Model

- Workspace owner is full editor.
- Workspace members can be `viewer` or `editor`.
- Page can be shared per user with `viewer` or `editor` role.
- Effective page role is highest permission between workspace membership and page share.

## Tests

```bash
.venv/bin/python manage.py test
```
