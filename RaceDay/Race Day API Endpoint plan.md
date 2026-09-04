# RaceDay API Endpoint Plan

## Base URL: `/api`

---

## Authentication Endpoints

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|-------------|-------|-------------|---------------|--------------|-------------------|
| POST | `/api/auth/register` | Register a new user account (Participant or Organiser) | Public | `{ "email": "string", "password": "string", "full_name": "string", "role": "string", "date_of_birth": "date", "phone_number": "string" }` | **201 Created** - User object with token<br>**400 Bad Request** - Validation errors<br>**409 Conflict** - Email already exists |
| POST | `/api/auth/login` | Authenticate user and return JWT token | Public | `{ "email": "string", "password": "string" }` | **200 OK** - `{ "token": "string", "user": {user object} }`<br>**401 Unauthorized** - Invalid credentials |
| POST | `/api/auth/logout` | Invalidate user's current session/token | Any (logged in) | None | **200 OK** - `{ "message": "Logged out successfully" }` |
| GET | `/api/auth/me` | Get current authenticated user's profile | Any (logged in) | None | **200 OK** - User object<br>**401 Unauthorized** - Not authenticated |

---

## User Profile Endpoints

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|-------------|-------|-------------|---------------|--------------|-------------------|
| GET | `/api/users/{id}` | Get user profile by ID | Any (logged in) | None | **200 OK** - User object (limited fields for non-owners)<br>**404 Not Found** - User not found |
| PUT | `/api/users/{id}` | Update user profile | Any (logged in, own profile) | `{ "full_name": "string", "date_of_birth": "date", "phone_number": "string" }` | **200 OK** - Updated user object<br>**403 Forbidden** - Cannot update other users<br>**404 Not Found** - User not found |
| PUT | `/api/users/{id}/password` | Update user password | Any (logged in, own profile) | `{ "current_password": "string", "new_password": "string" }` | **200 OK** - `{ "message": "Password updated" }`<br>**400 Bad Request** - Invalid current password<br>**404 Not Found** - User not found |
| GET | `/api/users/{id}/enrolments` | Get all event enrolments for a user | Any (logged in) | None | **200 OK** - Array of enrolment objects with event and category details<br>**404 Not Found** - User not found |
| GET | `/api/users/{id}/results` | Get all results for a user | Any (logged in) | None | **200 OK** - Array of result objects with event and category details<br>**404 Not Found** - User not found |

---

## Event Management Endpoints

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|-------------|-------|-------------|---------------|--------------|-------------------|
| GET | `/api/events` | Get all events with filtering options | Public | None (query params: status, date_from, date_to, location) | **200 OK** - Array of event objects |
| GET | `/api/events/{id}` | Get detailed event information by ID | Public | None | **200 OK** - Event object with categories, weather, and route details<br>**404 Not Found** - Event not found |
| POST | `/api/events` | Create a new event | Organiser | `{ "event_name": "string", "event_date": "date", "location": "string", "description": "string", "max_participants": "int", "registration_deadline": "date" }` | **201 Created** - Event object<br>**400 Bad Request** - Validation errors<br>**403 Forbidden** - Not an organiser |
| PUT | `/api/events/{id}` | Update an existing event | Organiser (owner) | `{ "event_name": "string", "event_date": "date", "location": "string", "description": "string", "max_participants": "int", "registration_deadline": "date", "event_status": "string" }` | **200 OK** - Updated event object<br>**403 Forbidden** - Not the organiser<br>**404 Not Found** - Event not found |
| DELETE | `/api/events/{id}` | Delete an event (soft delete - mark as cancelled) | Organiser (owner) | None | **200 OK** - `{ "message": "Event cancelled" }`<br>**403 Forbidden** - Not the organiser<br>**404 Not Found** - Event not found |
| GET | `/api/events/upcoming` | Get all upcoming events | Public | None | **200 OK** - Array of upcoming event objects |
| GET | `/api/events/my-events` | Get all events organised by the current user | Organiser | None | **200 OK** - Array of event objects created by the organiser<br>**403 Forbidden** - Not an organiser |

---

## Category Management Endpoints

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|-------------|-------|-------------|---------------|--------------|-------------------|
| GET | `/api/events/{event_id}/categories` | Get all categories for a specific event | Public | None | **200 OK** - Array of category objects<br>**404 Not Found** - Event not found |
| GET | `/api/categories/{id}` | Get category details by ID | Public | None | **200 OK** - Category object<br>**404 Not Found** - Category not found |
| POST | `/api/events/{event_id}/categories` | Create a new category for an event | Organiser (event owner) | `{ "category_name": "string", "distance_km": "decimal", "entry_fee": "decimal", "age_min": "int", "age_max": "int", "gender_restriction": "string", "capacity": "int", "start_time": "time" }` | **201 Created** - Category object<br>**403 Forbidden** - Not the event organiser<br>**404 Not Found** - Event not found |
| PUT | `/api/categories/{id}` | Update an existing category | Organiser (event owner) | `{ "category_name": "string", "distance_km": "decimal", "entry_fee": "decimal", "age_min": "int", "age_max": "int", "gender_restriction": "string", "capacity": "int", "start_time": "time" }` | **200 OK** - Updated category object<br>**403 Forbidden** - Not the event organiser<br>**404 Not Found** - Category not found |
| DELETE | `/api/categories/{id}` | Delete a category | Organiser (event owner) | None | **200 OK** - `{ "message": "Category deleted" }`<br>**403 Forbidden** - Not the event organiser<br>**404 Not Found** - Category not found |
| GET | `/api/events/{event_id}/categories/{category_id}/enrolments` | Get all enrolments for a specific category | Organiser (event owner) | None | **200 OK** - Array of enrolment objects with participant details<br>**403 Forbidden** - Not the event organiser<br>**404 Not Found** - Category not found |

---

## Event Enrolment Endpoints

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|-------------|-------|-------------|---------------|--------------|-------------------|
| POST | `/api/events/{event_id}/enrol` | Enrol a participant in an event category | Any (logged in) | `{ "category_id": "int" }` | **201 Created** - Enrolment object<br>**400 Bad Request** - Category full or validation errors<br>**404 Not Found** - Event or category not found<br>**409 Conflict** - Already enrolled |
| GET | `/api/enrolments/{id}` | Get enrolment details by ID | Any (logged in) | None | **200 OK** - Enrolment object with event, category, and participant details<br>**404 Not Found** - Enrolment not found |
| PUT | `/api/enrolments/{id}` | Update enrolment details (e.g., change category) | Any (logged in, own enrolment) | `{ "category_id": "int", "status": "string", "medical_conditions": "string", "emergency_contact": "string" }` | **200 OK** - Updated enrolment object<br>**403 Forbidden** - Cannot modify others' enrolments<br>**404 Not Found** - Enrolment not found |
| DELETE | `/api/enrolments/{id}` | Cancel enrolment/withdraw from event | Any (logged in, own enrolment) | None | **200 OK** - `{ "message": "Enrolment cancelled" }`<br>**403 Forbidden** - Cannot cancel others' enrolments<br>**404 Not Found** - Enrolment not found |
| GET | `/api/events/{event_id}/enrolments` | Get all enrolments for an event | Organiser (event owner) | None | **200 OK** - Array of enrolment objects with participant and category details<br>**403 Forbidden** - Not the event organiser<br>**404 Not Found** - Event not found |
| GET | `/api/events/{event_id}/enrolments/statistics` | Get enrolment statistics for an event | Organiser (event owner) | None | **200 OK** - Statistics object `{ "total": "int", "by_category": {}, "status_counts": {} }`<br>**403 Forbidden** - Not the event organiser<br>**404 Not Found** - Event not found |
| GET | `/api/me/enrolments` | Get all enrolments for the current user | Any (logged in) | None | **200 OK** - Array of enrolment objects with event and category details |

---

## Results Management Endpoints

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|-------------|-------|-------------|---------------|--------------|-------------------|
| POST | `/api/enrolments/{enrolment_id}/results` | Capture/upload results for a participant | Organiser (event owner) | `{ "finish_time": "time", "gun_time": "time", "chip_time": "time", "status": "string" }` | **201 Created** - Result object<br>**403 Forbidden** - Not the event organiser<br>**404 Not Found** - Enrolment not found<br>**409 Conflict** - Result already exists |
| GET | `/api/results/{id}` | Get result details by ID | Public | None | **200 OK** - Result object with enrolment and participant details<br>**404 Not Found** - Result not found |
| PUT | `/api/results/{id}` | Update/verify a result | Organiser (event owner) | `{ "finish_time": "time", "gun_time": "time", "chip_time": "time", "overall_position": "int", "category_position": "int", "gender_position": "int", "pace_per_km": "decimal", "status": "string" }` | **200 OK** - Updated result object<br>**403 Forbidden** - Not the event organiser<br>**404 Not Found** - Result not found |
| DELETE | `/api/results/{id}` | Delete/void a result | Organiser (event owner) | None | **200 OK** - `{ "message": "Result voided" }`<br>**403 Forbidden** - Not the event organiser<br>**404 Not Found** - Result not found |
| GET | `/api/events/{event_id}/results` | Get all results for an event | Public | None (query params: category_id) | **200 OK** - Array of result objects with participant details<br>**404 Not Found** - Event not found |
| GET | `/api/events/{event_id}/results/leaderboard` | Get leaderboard for an event | Public | None (query params: category_id) | **200 OK** - Array of ranked results with positions<br>**404 Not Found** - Event not found |
| GET | `/api/events/{event_id}/results/download` | Download all results as CSV/PDF | Organiser (event owner) | None | **200 OK** - CSV/PDF file<br>**403 Forbidden** - Not the event organiser<br>**404 Not Found** - Event not found |
| POST | `/api/events/{event_id}/results/bulk` | Bulk upload multiple results | Organiser (event owner) | `{ "results": [ { "enrolment_id": "int", "finish_time": "time", "position": "int" } ] }` | **201 Created** - Bulk upload summary<br>**400 Bad Request** - Invalid data format<br>**403 Forbidden** - Not the event organiser<br>**404 Not Found** - Event not found |

---

## Weather Information Endpoints

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|-------------|-------|-------------|---------------|--------------|-------------------|
| GET | `/api/events/{event_id}/weather` | Get weather forecast for an event | Public | None | **200 OK** - Weather object or array<br>**404 Not Found** - Event not found |
| POST | `/api/events/{event_id}/weather` | Add/update weather forecast | Organiser (event owner) | `{ "temperature": "decimal", "conditions": "string", "humidity": "int", "wind_speed": "decimal", "rainfall_mm": "decimal", "weather_source": "string" }` | **201 Created** - Weather object<br>**400 Bad Request** - Validation errors<br>**403 Forbidden** - Not the event organiser<br>**404 Not Found** - Event not found |
| PUT | `/api/weather/{id}` | Update weather information | Organiser (event owner) | `{ "temperature": "decimal", "conditions": "string", "humidity": "int", "wind_speed": "decimal", "rainfall_mm": "decimal" }` | **200 OK** - Updated weather object<br>**403 Forbidden** - Not the event organiser<br>**404 Not Found** - Weather record not found |
| GET | `/api/events/{event_id}/weather/forecast` | Get 5-day forecast for event location | Public | None | **200 OK** - Array of forecast objects<br>**404 Not Found** - Event not found |

---

## Route Information Endpoints

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|-------------|-------|-------------|---------------|--------------|-------------------|
| GET | `/api/events/{event_id}/routes` | Get all route information for an event | Public | None | **200 OK** - Array of route objects<br>**404 Not Found** - Event not found |
| GET | `/api/routes/{id}` | Get specific route details | Public | None | **200 OK** - Route object<br>**404 Not Found** - Route not found |
| POST | `/api/events/{event_id}/routes` | Add route information to an event | Organiser (event owner) | `{ "route_name": "string", "distance_km": "decimal", "elevation_gain": "int", "elevation_loss": "int", "route_description": "string", "gpx_file_url": "string", "water_points": "int", "aid_stations": "int" }` | **201 Created** - Route object<br>**403 Forbidden** - Not the event organiser<br>**404 Not Found** - Event not found |
| PUT | `/api/routes/{id}` | Update route information | Organiser (event owner) | `{ "route_name": "string", "distance_km": "decimal", "elevation_gain": "int", "elevation_loss": "int", "route_description": "string", "gpx_file_url": "string", "water_points": "int", "aid_stations": "int" }` | **200 OK** - Updated route object<br>**403 Forbidden** - Not the event organiser<br>**404 Not Found** - Route not found |
| DELETE | `/api/routes/{id}` | Delete route information | Organiser (event owner) | None | **200 OK** - `{ "message": "Route deleted" }`<br>**403 Forbidden** - Not the event organiser<br>**404 Not Found** - Route not found |

---

## Dashboard & Statistics Endpoints

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|-------------|-------|-------------|---------------|--------------|-------------------|
| GET | `/api/dashboard/organiser` | Get organiser dashboard statistics | Organiser | None | **200 OK** - `{ "total_events": "int", "total_participants": "int", "upcoming_events": "int", "revenue": "decimal", "recent_activity": [] }`<br>**403 Forbidden** - Not an organiser |
| GET | `/api/dashboard/participant` | Get participant dashboard statistics | Any (logged in) | None | **200 OK** - `{ "total_events_entered": "int", "upcoming_events": "int", "completed_events": "int", "personal_bests": {}, "recent_results": [] }` |
| GET | `/api/events/{event_id}/statistics` | Get comprehensive statistics for an event | Public | None | **200 OK** - `{ "total_participants": "int", "by_category": {}, "gender_breakdown": {}, "age_breakdown": {}, "average_time": "time", "fastest_time": "time" }`<br>**404 Not Found** - Event not found |

---

## Endpoint Summary Statistics

| Category | Count |
|----------|-------|
| **Authentication** | 4 |
| **User Profile** | 5 |
| **Event Management** | 7 |
| **Category Management** | 6 |
| **Event Enrolment** | 6 |
| **Results Management** | 8 |
| **Weather Information** | 4 |
| **Route Information** | 5 |
| **Dashboard & Statistics** | 3 |
| **TOTAL** | **48** |

---

## Role-Based Access Summary

| Role | Allowed Operations |
|------|-------------------|
| **Public (No Auth)** | View events, categories, results, weather, routes |
| **Participant (Authenticated)** | Register/login, view own profile, enrol in events, view own enrolments and results, update own profile |
| **Organiser (Authenticated)** | All Participant permissions + Create/update/delete events, manage categories, capture results, view all event enrolments, generate reports |

---

## Notes & Conventions

### Authentication
- All endpoints except Public ones require a valid JWT token
- Token must be included in the `Authorization: Bearer {token}` header

### Pagination
- GET endpoints with list responses support pagination via `?page={page}&limit={limit}`
- Default: `page=1`, `limit=20`

### Filtering Parameters
| Parameter | Description | Example |
|-----------|-------------|---------|
| `status` | Filter by status | `?status=Upcoming` |
| `category_id` | Filter by category | `?category_id=1` |
| `date_from` | Start date filter | `?date_from=2026-01-01` |
| `date_to` | End date filter | `?date_to=2026-12-31` |
| `search` | Text search | `?search=comrades` |
| `sort_by` | Sort field | `?sort_by=event_date` |
| `sort_order` | Sort direction (ASC/DESC) | `?sort_order=DESC` |

### Status Codes
| Code | Meaning |
|------|---------|
| 200 | OK - Successful GET/PUT/DELETE |
| 201 | Created - Successful POST |
| 400 | Bad Request - Validation errors |
| 401 | Unauthorized - Authentication required |
| 403 | Forbidden - Insufficient permissions |
| 404 | Not Found - Resource doesn't exist |
| 409 | Conflict - Resource conflict (duplicate, etc.) |

### Error Response Format
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": {
      "field": "email",
      "issue": "must be a valid email address"
    }
  }
}