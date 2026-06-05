# Nativa — AI Language Learning App

Voice conversation app with AI corrections, progress tracking, and A1→C2 learning plans.

<img width="768" height="1162" alt="image" src="https://github.com/user-attachments/assets/3c499971-91c3-422f-be20-f8eeb17341b9" />

## Stack

| Layer | Technology |
|---|---|
| Mobile / Desktop | Flutter (Windows, Android, iOS) |
| Backend | .NET 8 Web API |
| ORM | Dapper (raw SQL, no magic) |
| Database | PostgreSQL 16 |
| AI | Claude API (Anthropic) |
| Auth | JWT Bearer tokens |
| Local infra | Docker Compose |

---

## Prerequisites

| Tool | Purpose | Install |
|---|---|---|
| Docker Desktop | Runs Postgres + .NET API | https://www.docker.com/products/docker-desktop |
| Flutter SDK | Runs the mobile/desktop app | https://docs.flutter.dev/get-started/install/windows |
| .NET 8 SDK | Only needed if running API without Docker | https://dotnet.microsoft.com/download |

---

## Quick start (Windows)

### 1. Get your Anthropic API key
Go to https://console.anthropic.com → API Keys → Create key

### 2. Set your API key
```
copy .env.example .env
```
Open `.env` and replace `your_key_here` with your actual key.

### 3. Start everything
```
start.bat
```
This will:
- Start PostgreSQL in Docker
- Build and start the .NET API in Docker
- Run database migrations automatically
- Launch the Flutter Windows app

---

## Manual start (step by step)

### Start the backend
```bash
# From project root
docker compose up --build -d
```

API runs at: http://localhost:5000  
Swagger UI:  http://localhost:5000/swagger

### Run the Flutter app

**Windows desktop (recommended for local dev):**
```bash
cd flutter_app
flutter pub get
flutter run -d windows
```

**Web (no Flutter Windows setup needed):**
```bash
cd flutter_app
flutter run -d chrome
```

**Android (connect a phone or start an emulator):**
```bash
cd flutter_app
flutter run -d android
```

---

## Project structure

```
nativa/
├── docker-compose.yml          # Postgres + API
├── start.bat                   # One-click start (Windows)
├── stop.bat                    # Stop all services
├── .env                        # Your API key goes here
│
├── backend-dotnet/
│   ├── Nativa.Api.csproj
│   ├── Program.cs              # App startup + DI wiring
│   ├── appsettings.json
│   ├── Dockerfile
│   ├── Controllers/
│   │   ├── AuthController.cs   # POST /api/auth/register, /login
│   │   ├── PlansController.cs  # GET /api/plans/dashboard, POST /api/plans
│   │   └── SessionsController.cs # POST /api/sessions/start, /message, /end
│   ├── Services/
│   │   ├── UserRepository.cs   # Dapper queries for users
│   │   ├── PlanRepository.cs   # Dapper queries for plans + progress
│   │   ├── SessionRepository.cs# Dapper queries for sessions + messages
│   │   ├── ClaudeService.cs    # Anthropic API calls
│   │   └── JwtService.cs       # Token generation
│   ├── Models/Models.cs        # Domain models
│   ├── DTOs/DTOs.cs            # Request/response shapes
│   ├── Data/
│   │   ├── DbConnectionFactory.cs
│   │   └── DatabaseMigrator.cs
│   └── Migrations/
│       └── schema.sql          # All tables + seed data
│
└── flutter_app/
    ├── pubspec.yaml
    └── lib/
        ├── main.dart
        ├── services/api_service.dart   # All HTTP calls
        ├── models/models.dart
        ├── providers/
        │   ├── auth_provider.dart
        │   ├── dashboard_provider.dart
        │   └── session_provider.dart
        └── screens/
            ├── login_screen.dart       # Login + Register tabs
            ├── dashboard_screen.dart   # Plans, progress, today's topic
            ├── create_plan_screen.dart # New language plan setup
            └── session_screen.dart     # Live conversation + corrections
```

---

## API endpoints

### Auth
```
POST /api/auth/register   { name, email, password }
POST /api/auth/login      { email, password }
```

### Plans & Dashboard
```
GET  /api/plans/dashboard          → user + all plans + recent sessions
POST /api/plans                    { language, targetLevel, sessionsPerWeek }
GET  /api/plans/{id}/topic         → today's suggested topic
```

### Sessions
```
POST /api/sessions/start           { planId }
POST /api/sessions/{id}/message    { text }
POST /api/sessions/{id}/end        { durationSeconds }
```

---

## XP system

| Action | XP earned |
|---|---|
| Complete a session | +50 base |
| Each user message | +5 |
| Session over 5 minutes | +25 bonus |

Level thresholds: A1=300 XP → A2=400 → B1=500 → B2=600 → C1=700 → C2

---

## Database schema

```
users               → id, email, name, password_hash
learning_plans      → id, user_id, language, current_level, target_level
sessions            → id, user_id, plan_id, topic, language, level
messages            → id, session_id, role, content
corrections         → id, session_id, user_id, original_text, corrected_text
progress            → id, user_id, plan_id, total_xp, streak_days
topics              → id, language, level, title (seeded)
```

---

## Stop everything
```
stop.bat
```
Or: `docker compose down`

To wipe the database too: `docker compose down -v`
