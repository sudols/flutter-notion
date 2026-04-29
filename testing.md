# Testing Guide — Flutter Notion Clone

This guide walks through getting both the Django backend and the Flutter Android app running together from scratch.

> [!NOTE]
> **Repo layout**
> ```
> flutter-notion/
> ├── app/          ← Flutter app (Android)
> ├── notion/       ← Django app
> ├── config/       ← Django settings
> ├── manage.py
> └── requirements.txt
> ```

---

## Prerequisites

| Tool | Version used | Check |
|---|---|---|
| Python | 3.14+ | `python3 --version` |
| FVM / Flutter | 3.38.9 stable | `fvm flutter --version` |
| Android emulator **or** physical device | API 21+ | Android Studio AVD Manager |

---

## Part 1 — Django Backend

### 1.1 Create and activate a virtual environment

```bash
cd /home/ark/dev/flutter-notion

python3 -m venv .venv
source .venv/bin/activate
```

### 1.2 Install dependencies

```bash
pip install -r requirements.txt
```

### 1.3 Run migrations

```bash
python manage.py migrate
```

### 1.4 Seed demo users *(optional but recommended)*

Creates two pre-built users — **alice / password123** and **bob / password123** — plus a sample page tree.

```bash
python manage.py seed_demo
```

### 1.5 Start the server

```bash
python manage.py runserver 0.0.0.0:8000
```

> [!IMPORTANT]
> Use `0.0.0.0:8000` (not `127.0.0.1`) so the Android emulator can reach it.
> The emulator maps your machine's localhost to `10.0.2.2`.

### 1.6 Verify the backend is up

Open a browser or run:

```bash
curl http://127.0.0.1:8000/api/workspaces/
# → {"detail":"Authentication credentials were not provided."} (401 = server is running)
```

---

## Part 2 — Flutter App (Android Emulator)

### 2.1 Check available emulators

```bash
fvm flutter emulators
```

Start one if needed (replace `Pixel_9_API_35` with your AVD name):

```bash
fvm flutter emulators --launch Pixel_9_API_35
```

Wait for the emulator to fully boot before continuing.

### 2.2 Confirm a device is visible

```bash
fvm flutter devices
```

You should see at least one Android entry.

### 2.3 Run the app

```bash
cd /home/ark/dev/flutter-notion/app

fvm flutter run
```

Flutter will build and install the app on the emulator. This takes ~1–2 minutes on the first run.

> [!NOTE]
> For a faster hot-reload development loop:
> - Press **r** in the terminal to hot-reload after a code change.
> - Press **R** to hot-restart (resets state).
> - Press **q** to quit.

---

## Part 3 — Physical Device

If you're testing on a real Android phone instead of the emulator:

### 3.1 Find your machine's LAN IP

```bash
ip route get 1 | awk '{print $7; exit}'
# e.g. 192.168.1.42
```

### 3.2 Update the API base URL

Edit `app/lib/api/api_client.dart`, line 5:

```dart
// Change this:
const String kBaseUrl = 'http://10.0.2.2:8000/api';

// To your machine's LAN IP:
const String kBaseUrl = 'http://192.168.1.42:8000/api';
```

### 3.3 Enable USB debugging on the phone

1. Go to **Settings → About Phone** → tap **Build Number** 7 times
2. Go to **Settings → Developer Options** → enable **USB Debugging**
3. Connect the phone via USB and accept the trust prompt

### 3.4 Run

```bash
cd /home/ark/dev/flutter-notion/app
fvm flutter run
```

---

## Part 4 — Running Django Tests

```bash
cd /home/ark/dev/flutter-notion
source .venv/bin/activate
python manage.py test
```

Expected output:

```
...
Ran 3 tests in X.XXs
OK
```

---

## Part 5 — Running Flutter Tests

```bash
cd /home/ark/dev/flutter-notion/app
fvm flutter test
```

Expected output:

```
00:04 +1: All tests passed!
```

---

## Quick Reference — API Endpoints

Base URL: `http://127.0.0.1:8000/api/`

| Method | URL | Description |
|---|---|---|
| `POST` | `/auth/register/` | Create account (max 2 users) |
| `POST` | `/auth/login/` | Get JWT tokens |
| `GET` | `/auth/me/` | Current user |
| `GET` | `/workspaces/` | List workspaces |
| `GET` | `/pages/?workspace=1&parent=null` | Root pages |
| `GET` | `/pages/?search=keyword` | Search pages |
| `POST` | `/pages/` | Create page |
| `PATCH` | `/pages/{id}/` | Update page title |
| `POST` | `/pages/{id}/archive/` | Archive page |
| `POST` | `/pages/{id}/restore/` | Restore from trash |
| `GET` | `/blocks/?page=1` | List blocks |
| `POST` | `/blocks/` | Create block |
| `PATCH` | `/blocks/{id}/` | Update block |
| `DELETE` | `/blocks/{id}/` | Delete block |
| `POST` | `/blocks/reorder/` | Reorder blocks |

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `Connection refused` on emulator | Make sure Django is running on `0.0.0.0:8000`, not `127.0.0.1:8000` |
| `Connection refused` on physical device | Update `kBaseUrl` to your LAN IP (see Part 3) |
| `Demo user limit reached` | Run `python manage.py flush` then `python manage.py seed_demo` to reset |
| App stuck on loading spinner | Check Django terminal for errors; make sure migrations are applied |
| `flutter_secure_storage` crash on emulator | Use an emulator with Google Play or API 23+; older API levels may lack keystore support |
| Hot-reload doesn't reflect model changes | Press **R** (hot-restart) instead of **r** (hot-reload) |
