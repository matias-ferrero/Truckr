# Truckr® backend (Rails)

Rails 8.1 API + admin panel for the Truckr® marketplace. SQLite + Propshaft + Importmap; auth/admin via ActiveAdmin + Devise.

## Quickstart

```sh
just backend-install   # bundle install
just backend-migrate   # bin/rails db:migrate
just backend-dev       # bin/rails server (http://localhost:3000)
just backend-test      # bundle exec rspec
```

## Admin panel (ActiveAdmin)

The app mounts an admin UI under `/admin` powered by [ActiveAdmin](https://activeadmin.info/) on top of Devise. Stylesheets are compiled by `dartsass-rails` (Propshaft does not transform Sass) — `active_admin.scss` builds to `app/assets/builds/active_admin.css`.

### First-time setup

```sh
just backend-migrate                                        # creates admin_users + active_admin_comments
SEED_ADMIN_EMAIL=admin@truckr.local \
SEED_ADMIN_PASSWORD=changeme \
cd backend && bin/rails db:seed                             # idempotent admin user
just backend-dev                                            # http://localhost:3000/admin
```

In `development` / `test`, missing env vars fall back to `admin@example.com` / `password`. **In `production`, `db:seed` aborts unless both env vars are set.**

### Registering admin resources

Drop a file under `app/admin/<resource>.rb`:

```ruby
ActiveAdmin.register Trip do
  permit_params :origin, :destination, :status
end
```

Restart the server; the resource appears in the AA sidebar at `/admin/trips`.

### Asset rebuilds

`bin/rails server` does not auto-rebuild Sass. While editing `*.scss`, run `bin/rails dartsass:watch` in a second terminal (or use `bin/dev` which runs both via foreman).
