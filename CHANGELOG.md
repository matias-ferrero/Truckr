# Changelog

## [0.2.0](https://github.com/tcorzo/fiuba-gestion-tp/compare/v0.1.10...v0.2.0) (2026-05-16)


### ⚠ BREAKING CHANGES

* **ux:** The on-page quote-request form on the landing page is removed. The hero CTA now routes to the "Para quién" section instead of scrolling to a quote panel that never submitted to the API.
* **auth:** The login request body shape moves from `{ email, password }` to `{ user: { email, password } }`. CSRF endpoints and the `/api/auth/csrf` route are gone.

### Features

* **admin:** enable full CRUD on all ActiveAdmin resources ([#175](https://github.com/tcorzo/fiuba-gestion-tp/issues/175)) ([d9ff6a7](https://github.com/tcorzo/fiuba-gestion-tp/commit/d9ff6a79ca2c287e23bda385c19162145582bec5))
* **admin:** user impersonation from ActiveAdmin via fragment-passed JWT ([#173](https://github.com/tcorzo/fiuba-gestion-tp/issues/173)) ([898c32f](https://github.com/tcorzo/fiuba-gestion-tp/commit/898c32f085f01f1ed8b5f1a74816787e07ff81f9))
* **auth:** implement registration, login, sessions and frontend screens ([#145](https://github.com/tcorzo/fiuba-gestion-tp/issues/145)) ([51af7f4](https://github.com/tcorzo/fiuba-gestion-tp/commit/51af7f4c41cd32c226f49dd3ad5e73bc76dc6545))
* **auth:** migrate to stateless JWT auth (devise-jwt + JTI Matcher) ([#167](https://github.com/tcorzo/fiuba-gestion-tp/issues/167)) ([75bcfab](https://github.com/tcorzo/fiuba-gestion-tp/commit/75bcfab7a04a6fa863ed8fd3bb5ed0ff5d9c0f42))
* **carriers:** public carrier profile + quote estimator (US6) ([#164](https://github.com/tcorzo/fiuba-gestion-tp/issues/164)) ([5d1ba2d](https://github.com/tcorzo/fiuba-gestion-tp/commit/5d1ba2d624ea23d3674fa8dacac4958e3e9bce04))
* **dashboard:** initial dashboard implementation ([#162](https://github.com/tcorzo/fiuba-gestion-tp/issues/162)) ([0bc884c](https://github.com/tcorzo/fiuba-gestion-tp/commit/0bc884ce73f697e34c4b97fde3def230554032e7))
* **transport window:** carrier search and date-range filtering ([#159](https://github.com/tcorzo/fiuba-gestion-tp/issues/159)) ([dc3cf53](https://github.com/tcorzo/fiuba-gestion-tp/commit/dc3cf53102e615ec51ac175e2d2054822d539231))
* **transport-windows:** transport window CRUD for carrier availability (US9) ([#163](https://github.com/tcorzo/fiuba-gestion-tp/issues/163)) ([c0c66d2](https://github.com/tcorzo/fiuba-gestion-tp/commit/c0c66d2738a854e1846507753520156a41fc496c))
* **ux:** streamline navigation/UX and adopted schadcn/ui + tailwindcss ([#170](https://github.com/tcorzo/fiuba-gestion-tp/issues/170)) ([36589c5](https://github.com/tcorzo/fiuba-gestion-tp/commit/36589c5da8baeac7f42732b25c669bfba2aa1ba1))
* **vehicles:** registration with photos and multi-vehicle fleet support ([#144](https://github.com/tcorzo/fiuba-gestion-tp/issues/144)) ([e1fc01f](https://github.com/tcorzo/fiuba-gestion-tp/commit/e1fc01f718d461f8e672a5ddace1a12a8b5cf4ee))


### Bug Fixes

* **auth:** polish sign-up error messages ([#182](https://github.com/tcorzo/fiuba-gestion-tp/issues/182)) ([aec58b6](https://github.com/tcorzo/fiuba-gestion-tp/commit/aec58b6a8678766caa3ebd2c41a08d930dd3c78a))
* **carrier:** center delete vehicle modal ([#180](https://github.com/tcorzo/fiuba-gestion-tp/issues/180)) ([76204e5](https://github.com/tcorzo/fiuba-gestion-tp/commit/76204e5e1f6bd27a984ae115b4c01734a27033ff))
* **ci:** replace amannn action with inline payload check ([#138](https://github.com/tcorzo/fiuba-gestion-tp/issues/138)) ([a3fdb95](https://github.com/tcorzo/fiuba-gestion-tp/commit/a3fdb95fe2cdc34e99fca2e95a0383c88bee0163))
* **ci:** run Playwright via node to unblock frontend e2e on main ([#179](https://github.com/tcorzo/fiuba-gestion-tp/issues/179)) ([b8449a7](https://github.com/tcorzo/fiuba-gestion-tp/commit/b8449a725430e3d11b36e98a3cabd6c095209624))
* **justfile:** compile ActiveAdmin SCSS on backend-dev ([#171](https://github.com/tcorzo/fiuba-gestion-tp/issues/171)) ([82d8411](https://github.com/tcorzo/fiuba-gestion-tp/commit/82d841136d717c1004b99dc0612a1e7dc81af5f1))
* **ux:** make signup page fit desktop viewport without scroll ([#181](https://github.com/tcorzo/fiuba-gestion-tp/issues/181)) ([da4a879](https://github.com/tcorzo/fiuba-gestion-tp/commit/da4a879df521674fee42c785979f0136e3bcb800))


### Reverts

* **user:** removed the option to be both a transportist and a carrier ([#158](https://github.com/tcorzo/fiuba-gestion-tp/issues/158)) ([3aae4aa](https://github.com/tcorzo/fiuba-gestion-tp/commit/3aae4aaa76499b6185f3eacf4aceb86a0fdfd8b0))

## [0.1.10](https://github.com/tcorzo/fiuba-gestion-tp/compare/v0.1.9...v0.1.10) (2026-05-09)


### Features

* add schedule artifact ([#61](https://github.com/tcorzo/fiuba-gestion-tp/issues/61)) ([3d9e6e6](https://github.com/tcorzo/fiuba-gestion-tp/commit/3d9e6e60d414d5a708a62850a223e8b07e4437c5))
* **cost-report:** remove section 10 (what this report doesn't include) ([f0b25f9](https://github.com/tcorzo/fiuba-gestion-tp/commit/f0b25f92ef170a3344eae04338a01888e445c89b))
* **cost-report:** remove section 2 (value framework) and renumber sections ([1c8b5af](https://github.com/tcorzo/fiuba-gestion-tp/commit/1c8b5af4728f9733c2bb0ed06315294c52616a29))
* **cost-report:** remove sections 6-9 (calibration plan, reporting cadence, investment guardrails, risks & assumptions) ([47c3c7e](https://github.com/tcorzo/fiuba-gestion-tp/commit/47c3c7e3d8caae26ea2d28e1373d9b49e141b49e))
* **cost-report:** reorder sections - move section 4 to first, section 1 to last ([d41d2fd](https://github.com/tcorzo/fiuba-gestion-tp/commit/d41d2fdba54eb3c03b429621d4cea9eed73409cf))
* **cost-report:** simplify to single costs tables ([e6e3afe](https://github.com/tcorzo/fiuba-gestion-tp/commit/e6e3afe88c6b8067758aa35cd7fbf3a555834aa4))
* **cost-report:** update section 2 team composition and rates ([dd5127b](https://github.com/tcorzo/fiuba-gestion-tp/commit/dd5127b138696aa262d285a99d5597a1c4cee43f))
* **usm:** add insurance sales module ([ddccb42](https://github.com/tcorzo/fiuba-gestion-tp/commit/ddccb42554d36f5aeebfeeb20439b20a37affea4)), closes [#57](https://github.com/tcorzo/fiuba-gestion-tp/issues/57)
* **USM:** add missing Insurance module ([991b08d](https://github.com/tcorzo/fiuba-gestion-tp/commit/991b08de3554b107602399849f673e647aa4efe4))
* **usm:** reorder user stories priority ([885da35](https://github.com/tcorzo/fiuba-gestion-tp/commit/885da3516a02e256e1a5c682a58e1957e571dd25)), closes [#57](https://github.com/tcorzo/fiuba-gestion-tp/issues/57)


### Bug Fixes

* **cost-report:** update cost estimates and descriptions for clarity ([ecbc4a5](https://github.com/tcorzo/fiuba-gestion-tp/commit/ecbc4a50f5e42fd45afe88b9d60ee3a509581bc4))
* **cost-report:** update server references and adjust cost estimates in AWS infrastructure ([3d8dc5f](https://github.com/tcorzo/fiuba-gestion-tp/commit/3d8dc5f1554d9a8201ae749a60be1b07bc610fa9))
* **risks:** update artifact using course template ([#129](https://github.com/tcorzo/fiuba-gestion-tp/issues/129)) ([f62e056](https://github.com/tcorzo/fiuba-gestion-tp/commit/f62e056935f3215a2300db1cfa882b824b92cb7e))
* **sdlc:** use parenthesized exception tuple in sync.py ([#76](https://github.com/tcorzo/fiuba-gestion-tp/issues/76)) ([1ad8b06](https://github.com/tcorzo/fiuba-gestion-tp/commit/1ad8b0694e45d0603add0c37da210d845bed32ae))

## [0.1.9](https://github.com/tcorzo/fiuba-gestion-tp/compare/v0.1.8...v0.1.9) (2026-04-15)


### Bug Fixes

* **cost-report:** adjust table column configuration for better layout ([37dcd88](https://github.com/tcorzo/fiuba-gestion-tp/commit/37dcd88d14fffaa0b49d230c42b1b73535106459))

## [0.1.8](https://github.com/tcorzo/fiuba-gestion-tp/compare/v0.1.7...v0.1.8) (2026-04-15)


### Features

* add AWS infrastructure section to cost report ([9066880](https://github.com/tcorzo/fiuba-gestion-tp/commit/90668801a3b95375963e3a314b34c3cd8cda4486))
* add cost report section to main document ([687475d](https://github.com/tcorzo/fiuba-gestion-tp/commit/687475dec64110f03cc6bdb692401ff8ac134d3c))
* add Manuel Ramos persona and fix image path generation ([86e4dca](https://github.com/tcorzo/fiuba-gestion-tp/commit/86e4dca62cfc5880873e0f409feac2cc2802428e))
* add new personas - Carolina Souza (specialized transport) and Juan Martinez (last-mile urban delivery) ([7ad616c](https://github.com/tcorzo/fiuba-gestion-tp/commit/7ad616caaf13cba49caebc5c0fd7f191bc0f8e4f))
* add role labels to all persona cards ([19af47b](https://github.com/tcorzo/fiuba-gestion-tp/commit/19af47b184ae33dfee3ba5d4004f2475c22556d9))
* add Sofia persona - young occasional user/student ([4211271](https://github.com/tcorzo/fiuba-gestion-tp/commit/4211271f05b0967f8de38b6e86faa38a79bb7141))
* enumerate persona cards for improved readability ([a18949b](https://github.com/tcorzo/fiuba-gestion-tp/commit/a18949b5a6b8a10555a25a556d2c376cd5a4c2ab))
* overhaul backlog — 26 user stories with US{NNN} numbering and release structure ([ee1bca5](https://github.com/tcorzo/fiuba-gestion-tp/commit/ee1bca5c772428b7f420b090676d6fb698dab48f))
* redefine personas with improved diversity and edge case coverage ([399a458](https://github.com/tcorzo/fiuba-gestion-tp/commit/399a458ae54428fe2a02002415530b37e40da2ca))


### Bug Fixes

* remake Work Breakdown Structure (WBS) diagram implementation ([fda3473](https://github.com/tcorzo/fiuba-gestion-tp/commit/fda347344894477070a905001536a63e99338491))
* remove unnecessary blank line in WBS structure ([c8c59c9](https://github.com/tcorzo/fiuba-gestion-tp/commit/c8c59c989b985457cdea5e19602b3a9dad8734e5))
* update cost estimates and clarify AWS infrastructure details in cost report ([139e4d1](https://github.com/tcorzo/fiuba-gestion-tp/commit/139e4d1efc54c5de8e2596c56d9ef2a15faf0508))

## [0.1.7](https://github.com/tcorzo/fiuba-gestion-tp/compare/v0.1.6...v0.1.7) (2026-04-11)


### Features

* add smooth color gradient scale to average row ([7a647ce](https://github.com/tcorzo/fiuba-gestion-tp/commit/7a647cefc546f1656f0823970fddd211a70523dd))


### Bug Fixes

* align features matrix colors and styling with spreadsheet ([256411d](https://github.com/tcorzo/fiuba-gestion-tp/commit/256411d9315fc44e0fb8d964b3386c9027f29503))
* make features matrix generation dynamic from spreadsheet ([dd300c7](https://github.com/tcorzo/fiuba-gestion-tp/commit/dd300c700e6899f17216f5a17802610a857b40b8))

## [0.1.6](https://github.com/tcorzo/fiuba-gestion-tp/compare/v0.1.5...v0.1.6) (2026-04-10)


### Features

* add color support to USM artifact from Google Sheets ([ab0fcfb](https://github.com/tcorzo/fiuba-gestion-tp/commit/ab0fcfb61454806733b353e48dd806fecbaa06dc))

## [0.1.5](https://github.com/tcorzo/fiuba-gestion-tp/compare/v0.1.4...v0.1.5) (2026-04-01)


### Features

* update chat session documentation and rename 2029 to 2026 ([869b390](https://github.com/tcorzo/fiuba-gestion-tp/commit/869b390581c0a1167c8d7e5ec8dc8ae8ff806e62))

## [0.1.4](https://github.com/tcorzo/fiuba-gestion-tp/compare/v0.1.3...v0.1.4) (2026-04-01)


### Features

* add photos to personas in documentation ([081021c](https://github.com/tcorzo/fiuba-gestion-tp/commit/081021c4480b70207a2ed9bda760ddfb480f86cd))

## [0.1.3](https://github.com/tcorzo/fiuba-gestion-tp/compare/v0.1.2...v0.1.3) (2026-03-31)


### Bug Fixes

* inline build job into release-please workflow ([1d39f9b](https://github.com/tcorzo/fiuba-gestion-tp/commit/1d39f9bb2abdf37c78fb2ee93467a8882c394230))
* inline build job into release-please workflow ([fcea8fe](https://github.com/tcorzo/fiuba-gestion-tp/commit/fcea8fe961973ae95a2bbcccc4f7b21bf0070bb0))

## [0.1.2](https://github.com/tcorzo/fiuba-gestion-tp/compare/v0.1.1...v0.1.2) (2026-03-31)


### Features

* add new chat session documentation for 31/03/2026 ([2473d56](https://github.com/tcorzo/fiuba-gestion-tp/commit/2473d562aeb0fae18273ac88eaea52781f3da4b9))


### Bug Fixes

* update release process to trigger on main branch instead of release ([3026d60](https://github.com/tcorzo/fiuba-gestion-tp/commit/3026d606b345aa7c15c21fb148ef11a24eab7a75))

## [0.1.1](https://github.com/tcorzo/fiuba-gestion-tp/compare/v0.1.0...v0.1.1) (2026-03-31)


### Features

* add .gitignore and main.typ for project structure and documentation ([fb4fd0c](https://github.com/tcorzo/fiuba-gestion-tp/commit/fb4fd0c3e0a5644dfbe0aa0b2baf06e6678e9990))
* add automated release process with GitHub Actions and release-please configuration ([615d1b0](https://github.com/tcorzo/fiuba-gestion-tp/commit/615d1b02df0c5a4264228bf58ac298aa3c80a53a))
* add Brand Guardian agent documentation for comprehensive brand strategy and identity management ([8bf5adc](https://github.com/tcorzo/fiuba-gestion-tp/commit/8bf5adc0da1f31eff0c868d8a22493e2f2b4b342))
* add chat session export functionality and Typst file generation ([acd6568](https://github.com/tcorzo/fiuba-gestion-tp/commit/acd65680360d5bd8c8d7e86cb263a1acd8d07bde))
* add initial project planning artifacts and prerequisites documentation ([1624e28](https://github.com/tcorzo/fiuba-gestion-tp/commit/1624e2829bba230139c43f40a9798765fb8018c2))
* add pre-commit configuration and update tools in mise.toml ([cdac335](https://github.com/tcorzo/fiuba-gestion-tp/commit/cdac335e0097b9cd698a0728fb4fc635a9835d53))
* add Product Manager agent documentation with detailed role description and tools ([c239769](https://github.com/tcorzo/fiuba-gestion-tp/commit/c23976988d733d340271f6b0c2eddde7f752ac40))
* add project guidelines and tooling instructions in copilot-instructions.md ([6a489e3](https://github.com/tcorzo/fiuba-gestion-tp/commit/6a489e36e67dfa2067d7d290846431af3e3a4de4))
* add user stories, personas, and product vision documentation ([d7066c5](https://github.com/tcorzo/fiuba-gestion-tp/commit/d7066c5ed5fa2f4b2e8d09ab3a47f58209e6cdb1))
* add Work Breakdown Structure (WBS) and update document structure ([2cb77d3](https://github.com/tcorzo/fiuba-gestion-tp/commit/2cb77d37836e223550b2a9b6f30181f9419d13b0))
* enhance Typst documentation and chat session management with new build system ([a8c4c9e](https://github.com/tcorzo/fiuba-gestion-tp/commit/a8c4c9e7aa49dbe070caeec02d147ad999e95595))
* enhance User Story Map for Productor and Transportista with structured tasks and MVP details ([41eff3c](https://github.com/tcorzo/fiuba-gestion-tp/commit/41eff3cd138321c86bee8787040cc5a5698dc5b1))
* implement artifact generation from Excel to Typst format ([74bddf8](https://github.com/tcorzo/fiuba-gestion-tp/commit/74bddf8792c88780e5c1ca4b68d70a6f5106f061))
* refactor personas documentation to use persona-card structure for improved readability ([e296d35](https://github.com/tcorzo/fiuba-gestion-tp/commit/e296d3532fa5092654352f2a9fff2d258e4c862c))
* update import paths to use relative references and add shared template for project artifacts ([1926e15](https://github.com/tcorzo/fiuba-gestion-tp/commit/1926e153c828198e735f34bcc1cf00f5021ad577))
* update templates and user story maps for consistency and improved readability ([f296ded](https://github.com/tcorzo/fiuba-gestion-tp/commit/f296deddd8cf306720f4f213ceaa99e78df471f0))


### Bug Fixes

* update actions/checkout and typst-community/setup-typst versions for improved compatibility ([ef82f96](https://github.com/tcorzo/fiuba-gestion-tp/commit/ef82f969671d111c544598d30c651572d261a684))
