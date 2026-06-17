# Liftd — Workout Tracker

Projekt zaliczeniowy — aplikacja iOS + REST API + baza danych.

**Dokumentacja projektu:** [`DOKUMENTACJA.md`](DOKUMENTACJA.md)

| Warstwa | Technologia |
| --- | --- |
| iOS | SwiftUI, SwiftData |
| Backend | FastAPI, SQLAlchemy |
| Baza serwerowa | SQLite (dev) / PostgreSQL |
| Baza lokalna (iOS) | SwiftData |
| Logowanie | Google Sign-In + JWT |

Dokumentacja API i schemat bazy: [`PRD.md`](PRD.md)

## Uruchomienie

### 1. Backend

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn app.main:app --reload --port 8000
```

- API: http://localhost:8000/docs
- Health: http://localhost:8000/health

### 2. Aplikacja iOS

1. Otwórz `workout-tracker.xcodeproj` w Xcode.
2. Uruchom backend (krok 1).
3. Uruchom aplikację na symulatorze (scheme: `workout-tracker`).
4. Zaloguj się przez Google.

W trybie Debug aplikacja łączy się z `http://localhost:8000/api/v1`.

### 3. Dane demonstracyjne (opcjonalnie)

Po pierwszym logowaniu można zasilić konto przykładowymi szablonami i historią treningów:

```bash
cd backend
source .venv/bin/activate
python -m app.seed_demo --list              # lista użytkowników w bazie
python -m app.seed_demo --email ADRES@EMAIL  # seed dla wybranego konta
```

Następnie odśwież dane w aplikacji (pull-to-refresh na zakładkach Workout i History).

## Testy

```bash
cd backend
source .venv/bin/activate
pytest tests/ -v
```

## Struktura

```
backend/          — FastAPI REST API
workout-tracker/  — aplikacja iOS
PRD.md            — dokumentacja produktu i API
```
