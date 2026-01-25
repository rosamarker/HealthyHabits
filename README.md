# HealthyHabits

HealthyHabits is a Flutter app for a personal trainer to get a comprehensive view of daily activities and monitor clients’ progress using MoveSense devices.

This repository is developed as a **course project**.

## Core Features

- **Client management**
  - Create, edit, and delete clients
  - Store age, gender, motivation notes, and exercise plans
  - Status color coding (green / yellow / red)

- **Calendar overview**
  - Monthly calendar view
  - Appointment markers and appointment list for selected date

- **MoveSense integration (BLE)**
  - Scan and connect to MoveSense sensors
  - Stream heart rate
  - Record heart rate sessions while linked to a client

- **Local persistence**
  - Clients and their metadata are stored locally
  - Recorded sessions and samples are stored locally (for use after app restart)

- **Export**
  - Export recordings for a client to **JSON** for later analysis (e.g., Python notebooks)

## How to Use the App (Step-by-step)

1. **Create a client**
   - Tap **Add client** (floating + button).
   - Enter client details (name, age, gender, status, motivation).
   - Add exercises (reps/sets or timed).
   - Save.

2. **Link a MoveSense device to a client**
   - Open the client (Client List → tap the client).
   - In the **Movesense sensor** block:
     - Tap **Connect** and choose the MoveSense device from the list.
   - Select the client from the **Link / Record for client** dropdown.
   - Tap **Link** to store the device association on the client.

3. **Start HR streaming**
   - In the **Movesense sensor** block, tap **Start HR**.
   - Heart rate values should update continuously while streaming is active.

4. **Record a session**
   - Ensure a client is selected/linked in the Movesense block.
   - Tap **Record** to start recording heart rate samples for that client.
   - Tap **Stop rec** to stop and finalize the session.

5. **Export a client’s recordings to JSON**
   - Open the client detail page.
   - Tap **Export JSON** (download icon / button).
   - The app writes a JSON file containing the client metadata and recorded sessions.
   - The export dialog shows the full file path (copy it if needed).

## Tech Stack

- Flutter (Dart)
- `flutter_reactive_ble` (Bluetooth Low Energy)
- `table_calendar` (calendar UI)
- `sembast` (local database)
- `path_provider` (file locations)
- `stop_watch_timer` (timed exercises)

## Project Structure

```text
lib/
  model/           Data models (Client, Exercise, SessionSummary, etc.)
  services/        Persistence + domain services (repositories, export, recording)
  view_model/      UI state management (ChangeNotifier-based)
  view/            Screens (Home, Client list, Client detail, Create/Edit client)
  widgets/         Reusable UI components
