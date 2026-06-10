# QuickSlot

Book sports slots — badminton courts, turf grounds. No double bookings, ever.

---

## Running locally

### Backend

```bash
cd server
npm install
```

Make a `.env` file in `/server`:
```
DATABASE_URL=your_postgres_connection_string
```

Then:
```bash
npx ts-node db/seed.ts   # seeds venues + slots
npm run dev              # starts on localhost:3000
```

### Flutter

```bash
cd app
flutter pub get
flutter run
```

The app talks to `10.0.2.2:3000` by default — that's how Android emulator reaches your machine's localhost. If you're on a physical device, update `baseUrl` in `core/constants/api_constants.dart` to your machine's local IP.

---

## How it's structured

```
app/lib/
  core/         → theme, router, dio client, Result<T> error type
  features/
    auth/       → pick a user (hardcoded, as per spec)
    venues/     → browse venues, see slots by date
    bookings/   → confirm a booking, view and cancel your bookings

server/
  app/api/      → REST endpoints
  db/           → schema + seed script
  lib/          → postgres connection pool
```

Each feature folder follows the same pattern — `data` (API calls, models) → `domain` (entities, no Flutter) → `presentation` (screens, providers). The idea is the UI never touches raw JSON and the data layer never touches Flutter widgets.

State management is Riverpod. `FutureProvider` for anything fetched from the API. `NotifierProvider` for the booking flow which has multiple states (idle → loading → success / slot taken / failed). GoRouter handles navigation.

---

## The double booking problem

This was the main thing to get right. The naive approach — read the slot status, then write if available — breaks under concurrent requests because two users can both read "available" before either has written "booked".

The fix is a `SELECT ... FOR UPDATE` inside a transaction:

```
BEGIN
SELECT id, status FROM slots WHERE id = $1 FOR UPDATE  ← locks this row
  if status = 'booked' → ROLLBACK → return 409
UPDATE slots SET status = 'booked'
INSERT INTO bookings
COMMIT
```

The row lock means if two requests hit the same slot at the same instant, one waits at the SELECT while the other finishes. The second one then reads the updated status and returns 409. On the Flutter side, a 409 response shows a specific "slot just taken" dialog and takes the user back to the grid to pick another time — not a generic error.

---

## Auth

Kept it light as the spec says — three hardcoded users, user ID sent as an `X-User-Id` header on every request. The backend trusts it without verification. For a real app you'd swap this out for JWT or session tokens, but that wasn't the point here.

---

## What I cut

**Real-time slot updates** — if user A books a slot while user B is looking at the same grid, user B won't see it flip to grey until they change the date and come back. To fix this properly you'd need a WebSocket or at least polling every few seconds. The concurrency protection still works — user B would get the "slot just taken" dialog if they try to book it — but the grid doesn't update live.

**Offline support** — My Bookings refetches every time you open the screen. Would add a local cache with Hive for that.

---

## What I'd do with one more day

- Live slot updates via WebSocket so the grid reflects real-time availability without restarting
- Hive cache for My Bookings so it works offline
- One or two widget tests for the booking state machine
- Docker Compose for the backend so setup is just `docker compose up`
