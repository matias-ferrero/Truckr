#import "@preview/cmarker:0.1.8"

= Fix missing active_admin.css asset error

_2026-05-06 19:52 UTC — rama `main` — claude-opus-4-7_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  Propshaft::MissingAssetError in ActiveAdmin::Devise::Sessions#new

  Showing /home/[user]/.local/share/mise/installs/ruby/3.4.4/lib/ruby/gems/3.4.0/gems/activeadmin-3.5.1/app/views/layouts/active_admin_logged_out.html.erb where line #13 raised:

  The asset 'active_admin.css' was not found in the load path.

  Extracted source (around line #50):

  48
  49
  50
  51
  52
  53




      # Resolves the full path for an asset, raising an error if not found.
      def compute_asset_path(path, options = {})
        Rails.application.assets.resolver.resolve(path) || raise(MissingAssetError.new(path))
      end

      # Enhanced +stylesheet_link_tag+ with integrity support and bulk inclusion options.



  When entering http://localhost:3000/admin/login
  ```,
  h1-level: 4,
  label-prefix: "cc1467-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Cause: `app/assets/builds/active_admin.css` missing. Propshaft serves from `app/assets/builds`, dartsass-rails compiles `active_admin.scss` there but `bin/rails dartsass:build` hasn't run.

  Building now.
  ```,
  h1-level: 4,
  label-prefix: "cc1468-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Built. `app/assets/builds/active_admin.css` now 59KB. Reload `http://localhost:3000/admin/login` — error should clear.

  For ongoing dev, run `bin/dev` instead of `bin/rails server` — Procfile.dev runs `dartsass:watch` alongside the web server so SCSS changes recompile automatically. Deprecation warnings (`lighten`/`darken`) come from upstream activeadmin 3.5.1 SCSS, harmless.
  ```,
  h1-level: 4,
  label-prefix: "cc1469-",
)
