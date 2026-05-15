---
tag: REQ-BE-00023
title: Auth fullstack — registro, login, sesiones + pantallas en frontend
priority: P0
status: done
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/103
author: Claude Code
github_issue: 103
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtCd0
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-15T13:49:41.241252+00:00Z
labels:
- BE
- FE
- REQ
- mvp
- foundation
- auth
plan: docs/features/REQ/REQ-BE-00023/REQ-BE-00023-auth-fullstack.plan.md
pr_url: https://github.com/tcorzo/fiuba-gestion-tp/pull/145
---

## Summary

Implement end-to-end authentication: backend registration/login/logout/current-session endpoints, corresponding frontend screens, session persistence, and exposure of `current_user` to all `Api::*Controller`s. Covers US1 (Register), US2 (Login), and lays the groundwork for US3 (Edit Profile) and US16 (Change Password). This blocks **any** `/me/*` endpoint.

## Problem Statement

`CLAUDE.md` and the roadmap currently state "no auth yet". However, all previously created issues assume the existence of `current_user` (`carriers/me/...` endpoints, payouts, reviews, etc.). This issue closes that gap and delivers a usable end-to-end authentication system: a user can register as a Shipper or Carrier, log in, and operate with their profile.

## Expected Behavior

### Backend

* Session strategy: **httpOnly session cookie** + `SameSite=Lax` (no JWT — Rails session store + Solid Cache is sufficient and removes refresh token complexity). Record the decision in a short ADR if one does not already exist.
* Endpoints:

  * `POST /api/auth/register` — body: `{ email, password, name, role: "carrier"|"shipper"|"both" }`. Creates `User` + the corresponding `Carrier`/`Shipper` row (or both).
  * `POST /api/auth/login` — body: `{ email, password }`. Sets the session cookie.
  * `DELETE /api/auth/logout` — clears the session cookie.
  * `GET /api/auth/me` — returns `User` + roles + basic Carrier/Shipper data.
* `ApplicationController` exposes `current_user`, `authenticate_user!`, `current_carrier`, `current_shipper` (helpers).
* Basic login rate limiting (5 attempts / 15 min per IP) — use `rack-attack` or equivalent.
* Password validations: minimum 8 characters, at least one uppercase letter, one lowercase letter, and one number (US1 acceptance criteria).
* Send a welcome email (depends on `INF-BE-00005` mailer scaffolding).

### Frontend

* Screens: `/register`, `/login`, `/logout` (action), header with "Log in" / "Log out" CTA depending on session state.
* Registration form with required fields + role selector (Customer / Carrier / Both).
* Client-side validation for password confirmation + rules; server-side errors displayed inline.
* Session state persistence: initial poll to `GET /api/auth/me`; React Context for `useCurrentUser()`.
* Post-login redirect to the corresponding role home page (placeholder until US10 / US4 exist).
* Logout available from the header on every screen.
* E2E coverage: register + login + logout happy path in Playwright.

### Cross-cutting

* CORS configured so cookies work in development (`localhost:5173` ↔ `localhost:3000`), `credentials: include` enabled in fetch requests.
* CSRF: since this uses API session cookies, CSRF protection is required. Add `GET /api/csrf` returning the token; the frontend sends it via the `X-CSRF-Token` header on POST requests.

## Technical Notes

* **Session store**: Solid Cache (DB-backed), no Redis. Consistent with the project stack.
* **Password digest**: `User` already has `password_digest` from `REQ-BE-00020`; this issue only enables it via `has_secure_password validations: true`.
* **Roles**: the existence of a `Carrier`/`Shipper` row defines the role state. Do not add denormalized booleans (project rule).
* **Email verification**: NOT included here. Email verification belongs to US22 (Release 3); this issue accepts unverified users and marks them as `email_verified: false`.
* **Polished auth UI**: forms should follow `frontend/.impeccable.md` and require running the `polish`/`critique` skills in this issue.

## Related

* Parent issues: `REQ-BE-00020` (Identity models), `INF-BE-00005` (mailer — welcome email can be added later if necessary).
* Source user stories: US1, US2 (fully covered by this fullstack issue).
* Blocks: US3 (edit profile), US16 (change password), US22 (verify email), all `/me/*` endpoints.

## Acceptance Criteria

* [ ] `/api/auth/{register,login,logout,me,csrf}` endpoints implemented with request specs.
* [ ] `ApplicationController` exposes `current_user`, `current_carrier`, `current_shipper`, `authenticate_user!`.
* [ ] Login rate limiting is functional.
* [ ] `/register` and `/login` screens implemented and connected to the backend.
* [ ] Header displays session state + logout on every route.
* [ ] Password validation rules (all 4 US1 ACs) covered in backend and frontend.
* [ ] CORS + CSRF configured; fetch requests with `credentials: include` work correctly.
* [ ] E2E (Playwright): register → login → me → logout.
* [ ] Backend specs ≥80% coverage for `app/controllers/api/auth_controller.rb`.
* [ ] Frontend tests ≥80% coverage for auth components.
* [ ] Conventional commit: `feat(auth): implement registration and login`.
* [ ] All identifiers must be in English.
