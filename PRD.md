# 🏋️ Liftd — Mobilny Dziennik Treningowy

**Product Requirements Document**
iOS (SwiftUI) · FastAPI · PostgreSQL · Railway

| Wersja    | Technologie                    |
| --------- | ------------------------------ |
| 1.0 — MVP | SwiftUI / FastAPI / PostgreSQL |

---

## 1. Przegląd Projektu

### 1.1 Problem

Istniejące darmowe aplikacje do śledzenia treningów (np. SmartWorkout) nie pozwalają na tworzenie i wielokrotne używanie własnych planów treningowych — funkcja ta jest zablokowana za paywallem. Użytkownik chcący powtórzyć poprzedni trening musi ręcznie przeglądać historię i kopiować sesję, co jest niewygodne i czasochłonne.

### 1.2 Rozwiązanie

Liftd to natywna aplikacja iOS (SwiftUI), która dostarcza pełny, darmowy przepływ pracy dla osób trenujących siłowo:

- Tworzenie nazwanych szablonów treningowych z listą ćwiczeń
- Uruchamianie sesji z szablonu jednym tapnięciem
- Ad-hoc logowanie sesji bez szablonu
- Zapis sesji ad-hoc jako nowy szablon
- Pełna historia treningów
- Tryb offline — sesja zapisuje się lokalnie, sync w tle po powrocie internetu

### 1.3 Cel Projektu

Projekt zaliczeniowy realizowany w ramach przedmiotu. Demonstracja architektury klient-serwer z REST API, JWT auth, lokalną bazą danych i synchronizacją.

---

## 2. Zespół i Podział Zadań

| Rola           | Zakres odpowiedzialności                                                                  |
| -------------- | ----------------------------------------------------------------------------------------- |
| Frontend (iOS) | Cała aplikacja SwiftUI, SwiftData, integracja z API, Google OAuth, UI/UX                  |
| Backend        | FastAPI, modele danych, endpointy REST, JWT auth, seeding bazy ćwiczeń, deploy na Railway |

Repozytorium: Git (GitHub), osobne branche per feature, merge przez Pull Requesty.

---

## 3. Stack Technologiczny

| Warstwa               | Technologia                                               |
| --------------------- | --------------------------------------------------------- |
| iOS Frontend          | Swift 5.9+, SwiftUI, SwiftData (lokalna baza), URLSession |
| Autentykacja          | Google Sign-In SDK (iOS), JWT Bearer Token                |
| Backend               | Python 3.11+, FastAPI, Uvicorn                            |
| Baza danych (serwer)  | PostgreSQL (Railway managed)                              |
| Baza danych (lokalna) | SwiftData / SQLite (wbudowane w iOS)                      |
| Deploy                | Railway (backend + PostgreSQL)                            |
| Kontrola wersji       | Git + GitHub                                              |

---

## 4. Funkcjonalności — MVP

### 4.1 Autentykacja

- Logowanie przez Google OAuth 2.0 (Google Sign-In SDK)
- Po zalogowaniu backend zwraca JWT — token przechowywany bezpiecznie w iOS Keychain
- Automatyczne odświeżanie tokenu / wylogowanie po wygaśnięciu
- Ekran onboardingu dla nowego użytkownika

### 4.2 Lista Ćwiczeń

- Read-only lista ćwiczeń seedowana do bazy przy starcie serwera
- Kategorie: Push / Pull / Legs / Core / Cardio
- Wyszukiwanie po nazwie (search bar)
- Cache lokalny (SwiftData) — lista dostępna offline po pierwszym załadowaniu
- Przyszłość (poza MVP): możliwość dodawania własnych ćwiczeń przez użytkownika

### 4.3 Szablony Treningowe

- Tworzenie nazwanego szablonu z wybraną listą ćwiczeń
- Edycja szablonu (zmiana nazwy, dodanie/usunięcie ćwiczeń, zmiana kolejności)
- Usuwanie szablonu
- Lista szablonów na ekranie głównym (Workout tab)
- Cache szablonów lokalnie (SwiftData)

### 4.4 Sesja Treningowa

**Dwa tryby startu:**

- Start from Template — otwiera szablon z pre-wypełnionymi ćwiczeniami
- New Workout — pusta sesja, ćwiczenia dodawane ad-hoc z listy

**W trakcie sesji:**

- Lista ćwiczeń z możliwością dodawania kolejnych w locie
- Dla każdego ćwiczenia: tabela serii z polami kg i reps
- Przycisk ✓ Done przy każdej serii do oznaczenia jej jako ukończonej
- Timer wypoczynku (rest timer) — uruchamia się automatycznie po zatwierdzeniu serii
- Floating timer widoczny przez całą sesję
- Możliwość usunięcia ćwiczenia lub serii
- Przycisk Finish Workout — podsumowanie i zapis

**Zapis sesji:**

- Sesja zapisuje się na bieżąco w SwiftData (ochrona przed utratą danych)
- Po kliknięciu Finish — próba synchronizacji z serwerem
- Jeśli brak internetu — zapis w kolejce, sync w tle gdy internet wróci
- Po skończeniu sesji ad-hoc — opcja "Save as Template"

### 4.5 Historia Treningów

- Lista wszystkich ukończonych sesji posortowana chronologicznie
- Widok szczegółów sesji: data, czas trwania, lista ćwiczeń z seriami i ciężarami
- Dane historii cachowane lokalnie (dostępne offline)

### 4.6 Analytics (Placeholder)

- Tab obecny w nawigacji — na razie wyświetla ekran placeholder
- Infrastruktura gotowa do rozbudowy (wykresy postępu, 1RM calculator) w kolejnych wersjach

### 4.7 Profil

- Wyświetlanie danych konta (imię, email z Google, avatar)
- Przycisk Wyloguj
- Podstawowe ustawienia (do rozbudowy w przyszłości)

---

## 5. Strategia Offline (Opcja C)

**Zasada działania trybu offline:**

1. Pierwsze uruchomienie: wymagany internet — pobierana jest lista ćwiczeń i szablony
2. Kolejne uruchomienia: dane dostępne z cache (SwiftData) nawet bez sieci
3. Sesja treningowa: każda seria zapisywana na bieżąco lokalnie
4. Zakończenie sesji: próba sync z serwerem — jeśli offline, dane trafiają do kolejki sync
5. Powrót do sieci: aplikacja automatycznie wysyła zaległe sesje do backendu

| Stan sieci                 | Zachowanie aplikacji                                              |
| -------------------------- | ----------------------------------------------------------------- |
| Online                     | Pełna funkcjonalność, dane syncowane na bieżąco                   |
| Offline przy starcie sesji | Sesja uruchamia się normalnie z lokalnego cache                   |
| Offline w trakcie sesji    | Dane zapisywane lokalnie, bez przerwy w działaniu                 |
| Powrót online              | Automatyczny sync w tle (background task)                         |
| Konflikt danych            | W MVP: serwer jest źródłem prawdy, local override przy force-sync |

---

## 6. Architektura Nawigacji iOS

**Tab Bar — 4 zakładki:**

| Tab          | Opis                                          |
| ------------ | --------------------------------------------- |
| 💪 Workout   | Ekran główny: szablony + przycisk New Workout |
| 📋 History   | Lista ukończonych sesji                       |
| 📊 Analytics | Placeholder (przyszłe wykresy postępu)        |
| 👤 Profile   | Dane konta, ustawienia, wylogowanie           |

### 6.1 Hierarchia ekranów

**Workout Tab**

- `WorkoutHomeView` — lista szablonów + CTA New Workout
  - `TemplateDetailView` — podgląd/edycja szablonu
  - `ActiveSessionView` — ekran aktywnej sesji (modal full-screen)
  - `ExercisePickerView` — wyszukiwarka i wybór ćwiczenia (sheet)
  - `SessionSummaryView` — podsumowanie po zakończeniu sesji

**History Tab**

- `HistoryListView` — lista sesji
  - `SessionDetailView` — szczegóły wybranej sesji

**Analytics Tab**

- `AnalyticsPlaceholderView` — komunikat o nadchodzących funkcjach

**Profile Tab**

- `ProfileView` — dane użytkownika, ustawienia

---

## 7. Dokumentacja API

### 7.1 Informacje ogólne

- **Base URL:** `https://Liftd-api.railway.app/api/v1`
- **Autentykacja:** Bearer JWT token w nagłówku `Authorization`
- **Format:** JSON (`Content-Type: application/json`)
- **Wersjonowanie:** Prefix `/v1/` — gotowość na przyszłe wersje API

### 7.2 Auth

| Metoda | Endpoint        | Opis                                    | Auth   |
| ------ | --------------- | --------------------------------------- | ------ |
| POST   | `/auth/google`  | Weryfikacja Google ID Token, zwraca JWT | —      |
| POST   | `/auth/refresh` | Odświeżenie JWT                         | Bearer |
| POST   | `/auth/logout`  | Unieważnienie tokenu                    | Bearer |

### 7.3 Ćwiczenia

| Metoda | Endpoint                    | Opis                     | Auth   |
| ------ | --------------------------- | ------------------------ | ------ |
| GET    | `/exercises`                | Lista wszystkich ćwiczeń | Bearer |
| GET    | `/exercises/{id}`           | Szczegóły ćwiczenia      | Bearer |
| GET    | `/exercises?category={cat}` | Filtrowanie po kategorii | Bearer |
| GET    | `/exercises?search={q}`     | Wyszukiwanie po nazwie   | Bearer |

### 7.4 Szablony Treningowe

| Metoda | Endpoint          | Opis                        | Auth   |
| ------ | ----------------- | --------------------------- | ------ |
| GET    | `/templates`      | Lista szablonów użytkownika | Bearer |
| POST   | `/templates`      | Utwórz nowy szablon         | Bearer |
| GET    | `/templates/{id}` | Pobierz szablon             | Bearer |
| PUT    | `/templates/{id}` | Edytuj szablon              | Bearer |
| DELETE | `/templates/{id}` | Usuń szablon                | Bearer |

### 7.5 Sesje Treningowe

| Metoda | Endpoint         | Opis                       | Auth   |
| ------ | ---------------- | -------------------------- | ------ |
| GET    | `/sessions`      | Historia sesji użytkownika | Bearer |
| POST   | `/sessions`      | Zapisz ukończoną sesję     | Bearer |
| GET    | `/sessions/{id}` | Szczegóły sesji            | Bearer |
| DELETE | `/sessions/{id}` | Usuń sesję                 | Bearer |

### 7.6 Użytkownik

| Metoda | Endpoint    | Opis                          | Auth   |
| ------ | ----------- | ----------------------------- | ------ |
| GET    | `/users/me` | Dane zalogowanego użytkownika | Bearer |
| PATCH  | `/users/me` | Aktualizacja profilu          | Bearer |
| DELETE | `/users/me` | Usunięcie konta i danych      | Bearer |

### 7.7 Przykładowe zapytania i odpowiedzi

**POST /auth/google**

Request:

```json
{ "google_id_token": "eyJhbGciOiJSUzI1Ni..." }
```

Response 200:

```json
{
	"access_token": "eyJhbGci...",
	"token_type": "bearer",
	"user": { "id": "uuid", "email": "jan@gmail.com", "name": "Jan Kowalski" }
}
```

**POST /sessions**

Request body:

```json
{
	"started_at": "2025-01-15T10:00:00Z",
	"finished_at": "2025-01-15T11:15:00Z",
	"template_id": "uuid-or-null",
	"exercises": [
		{ "exercise_id": "uuid", "order": 1, "sets": [{ "set_number": 1, "weight_kg": 80, "reps": 8 }] }
	]
}
```

---

## 8. Schemat Bazy Danych

### 8.1 PostgreSQL (Serwer)

**Tabela: `users`**

| Kolumna    | Typ i opis                             |
| ---------- | -------------------------------------- |
| id         | UUID PRIMARY KEY                       |
| google_id  | VARCHAR(255) UNIQUE — ID z Google      |
| email      | VARCHAR(255) UNIQUE NOT NULL           |
| name       | VARCHAR(255)                           |
| avatar_url | TEXT                                   |
| created_at | TIMESTAMP WITH TIME ZONE DEFAULT now() |

**Tabela: `exercises`**

| Kolumna       | Typ i opis                                       |
| ------------- | ------------------------------------------------ |
| id            | UUID PRIMARY KEY                                 |
| name          | VARCHAR(255) NOT NULL                            |
| category      | VARCHAR(50) — Push / Pull / Legs / Core / Cardio |
| description   | TEXT                                             |
| muscle_groups | TEXT[] — tablica grup mięśniowych                |

**Tabela: `templates`**

| Kolumna    | Typ i opis                             |
| ---------- | -------------------------------------- |
| id         | UUID PRIMARY KEY                       |
| user_id    | UUID FK → users.id                     |
| name       | VARCHAR(255) NOT NULL                  |
| created_at | TIMESTAMP WITH TIME ZONE DEFAULT now() |
| updated_at | TIMESTAMP WITH TIME ZONE DEFAULT now() |

**Tabela: `template_exercises`**

| Kolumna     | Typ i opis                               |
| ----------- | ---------------------------------------- |
| id          | UUID PRIMARY KEY                         |
| template_id | UUID FK → templates.id ON DELETE CASCADE |
| exercise_id | UUID FK → exercises.id                   |
| order_index | INTEGER — kolejność w szablonie          |

**Tabela: `sessions`**

| Kolumna     | Typ i opis                        |
| ----------- | --------------------------------- |
| id          | UUID PRIMARY KEY                  |
| user_id     | UUID FK → users.id                |
| template_id | UUID FK → templates.id (nullable) |
| started_at  | TIMESTAMP WITH TIME ZONE          |
| finished_at | TIMESTAMP WITH TIME ZONE          |
| notes       | TEXT (nullable)                   |
| synced_at   | TIMESTAMP WITH TIME ZONE          |

**Tabela: `session_exercises`**

| Kolumna     | Typ i opis                              |
| ----------- | --------------------------------------- |
| id          | UUID PRIMARY KEY                        |
| session_id  | UUID FK → sessions.id ON DELETE CASCADE |
| exercise_id | UUID FK → exercises.id                  |
| order_index | INTEGER                                 |

**Tabela: `sets`**

| Kolumna             | Typ i opis                                       |
| ------------------- | ------------------------------------------------ |
| id                  | UUID PRIMARY KEY                                 |
| session_exercise_id | UUID FK → session_exercises.id ON DELETE CASCADE |
| set_number          | INTEGER                                          |
| weight_kg           | DECIMAL(6,2)                                     |
| reps                | INTEGER                                          |
| completed           | BOOLEAN DEFAULT false                            |

### 8.2 SwiftData — Lokalna baza iOS

| Model         | Odpowiednik w PostgreSQL               |
| ------------- | -------------------------------------- |
| ExerciseLocal | exercises (cache, read-only)           |
| TemplateLocal | templates (cache + offline)            |
| SessionDraft  | sessions (w trakcie sesji, przed sync) |
| SyncQueue     | Kolejka operacji oczekujących na sync  |

---

## 9. Obsługa Błędów

### 9.1 Kody HTTP

| Kod                       | Znaczenie                        |
| ------------------------- | -------------------------------- |
| 200 OK                    | Sukces                           |
| 201 Created               | Zasób utworzony                  |
| 400 Bad Request           | Nieprawidłowe dane wejściowe     |
| 401 Unauthorized          | Brak lub nieprawidłowy JWT       |
| 403 Forbidden             | Brak uprawnień do zasobu         |
| 404 Not Found             | Zasób nie istnieje               |
| 409 Conflict              | Konflikt danych (np. duplikat)   |
| 422 Unprocessable Entity  | Błąd walidacji (FastAPI default) |
| 500 Internal Server Error | Błąd serwera                     |

### 9.2 Format błędu

```json
{
	"error": "template_not_found",
	"message": "Template with given ID does not exist",
	"status_code": 404
}
```

### 9.3 Obsługa błędów w iOS

- Brak internetu: toast/banner informujący o trybie offline
- Błąd 401: automatyczne wylogowanie i przekierowanie na ekran logowania
- Błąd sync: wizualny wskaźnik niezsynchronizowanych sesji, możliwość ręcznego retry
- Błąd ładowania danych: empty state view z przyciskiem odświeżania

---

## 10. Mapa Wymagań Projektowych

| Komponent                | Maks. Punkty | Uzasadnienie                                            |
| ------------------------ | :----------: | ------------------------------------------------------- |
| Dokumentacja             |    **15**    | Niniejszy dokument PRD, schemat DB, opis endpointów     |
| Serwer                   |    **8**     | FastAPI na Railway, konfiguracja środowiska             |
| Implementacja API        |    **7**     | REST endpoints zgodne z best practices, walidacja       |
| Integracja z Bazą Danych |    **5**     | PostgreSQL, ORM (SQLAlchemy), migracje                  |
| Operacje CRUD            |    **7**     | Templates, Sessions, Exercises — pełne CRUD             |
| Uwierzytelnianie         |    **10**    | Google OAuth + JWT Bearer Token                         |
| Obsługa błędów           |    **7**     | HTTP status codes, error format, iOS error states       |
| UI/UX Aplikacji          |    **5**     | SwiftUI, natywny design, responsywność                  |
| Używanie API             |    **10**    | URLSession, poprawne wyświetlanie danych z backendu     |
| Lokalna Baza Danych      |    **8**     | SwiftData — cache ćwiczeń, szablonów, sesji in-progress |
| Synchronizacja danych    |    **10**    | SyncQueue, background sync, konflikt resolution         |
| Współpraca i Prezentacja |    **8**     | Git/GitHub, demo działania, podział zadań               |
| **RAZEM**                |   **100**    |                                                         |

---

## 11. Future Scope (poza MVP)

- Wykresy postępu — wzrost ciężaru w czasie dla danego ćwiczenia (Swift Charts)
- 1RM Calculator — szacowanie maksymalnego jednopowtórzeniowego ciężaru
- Push notifications — powiadomienie o końcu przerwy (rest timer)
- Gamifikacja — streak, odznaki, ranking
- Własne ćwiczenia — dodawanie przez użytkownika
- Apple Watch companion app
- Eksport danych (CSV / PDF)

---

_Liftd — PRD v1.0_
