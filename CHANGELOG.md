# Changelog

## [0.2.4](https://github.com/tcorzo/fiuba-gestion-tp/compare/v0.2.3...v0.2.4) (2026-06-18)


### Features

* **backend:** add console-remote helper for deployed Rails console ([#331](https://github.com/tcorzo/fiuba-gestion-tp/issues/331)) ([63509cd](https://github.com/tcorzo/fiuba-gestion-tp/commit/63509cd0600ca39803178c8f9c0fd782ab1344bb))
* **cargo:** autocalculado de distancia en carga vía Google Routes API (US53) ([#322](https://github.com/tcorzo/fiuba-gestion-tp/issues/322)) ([e7adf2d](https://github.com/tcorzo/fiuba-gestion-tp/commit/e7adf2da101fe40a187388112f31220a55383143))
* **cargo:** paginate compatible transport windows with total count ([#348](https://github.com/tcorzo/fiuba-gestion-tp/issues/348)) ([e2ec9ac](https://github.com/tcorzo/fiuba-gestion-tp/commit/e2ec9ac17c453e941b5b4f0680e9f96f2e4ef4c9))
* **carrier:** carrier dashboard v2 — job-funnel command center ([#345](https://github.com/tcorzo/fiuba-gestion-tp/issues/345)) ([63db6d4](https://github.com/tcorzo/fiuba-gestion-tp/commit/63db6d4bc305cc438cada3443ef5dd151a751914))
* **fulfilment:** shipment detail v2 — sticky action rail + two-column layout ([#343](https://github.com/tcorzo/fiuba-gestion-tp/issues/343)) ([1715694](https://github.com/tcorzo/fiuba-gestion-tp/commit/17156940d0c0e90f894d2441d9ccdee5ddde57c8))
* **fulfilment:** shipment map & Google Maps deep-links on detail (US51) ([#334](https://github.com/tcorzo/fiuba-gestion-tp/issues/334)) ([d3f27ad](https://github.com/tcorzo/fiuba-gestion-tp/commit/d3f27ad5cf6d735b2b6ed13136342d4c02d9e767))
* **fulfilment:** us15 — carrier payout on delivery (fullstack) ([#320](https://github.com/tcorzo/fiuba-gestion-tp/issues/320)) ([bbdeaf1](https://github.com/tcorzo/fiuba-gestion-tp/commit/bbdeaf1791b7f1f383663feddc6c872364c71dec))
* **infra:** provision VITE_GOOGLE_MAPS_API_KEY for staging and production ([#323](https://github.com/tcorzo/fiuba-gestion-tp/issues/323)) ([c0d3c5f](https://github.com/tcorzo/fiuba-gestion-tp/commit/c0d3c5f260629ea5362a792bde071daf7e7faeb4))
* **navigation:** persistent role-based sidebar; move "Mis Pagos" out of header ([#341](https://github.com/tcorzo/fiuba-gestion-tp/issues/341)) ([f822c80](https://github.com/tcorzo/fiuba-gestion-tp/commit/f822c8058b20591d04bedc4359405b81181d04d4))
* **shipper:** cargo-centric shipper dashboard v2 at /shipper/dashboard ([#332](https://github.com/tcorzo/fiuba-gestion-tp/issues/332)) ([5e6afb6](https://github.com/tcorzo/fiuba-gestion-tp/commit/5e6afb6524d27579e3f7d88dc5b256a2f035923d))


### Bug Fixes

* **cable:** allow CloudFront SPA origin for Action Cable in production ([#329](https://github.com/tcorzo/fiuba-gestion-tp/issues/329)) ([1ba3acf](https://github.com/tcorzo/fiuba-gestion-tp/commit/1ba3acfe582e199ced469171040507eefa48291d))
* **cargos:** backfill coordinates before NOT NULL constraint ([#328](https://github.com/tcorzo/fiuba-gestion-tp/issues/328)) ([9006315](https://github.com/tcorzo/fiuba-gestion-tp/commit/9006315554b3a50b103c6a9c079715cfb4659b85))
* **deps:** bump puma to 8.0.2 to patch PROXY protocol CVEs ([#326](https://github.com/tcorzo/fiuba-gestion-tp/issues/326)) ([fe47125](https://github.com/tcorzo/fiuba-gestion-tp/commit/fe47125b14071c8a453de2c5cf54cac4df5aa5cf))
* **fulfilment:** broadcast payout notification after the write transaction commits ([#337](https://github.com/tcorzo/fiuba-gestion-tp/issues/337)) ([e1aafbd](https://github.com/tcorzo/fiuba-gestion-tp/commit/e1aafbd7e2211594fe97686d10cb6e5bf78b41b2))
* **review:** enforce per-session ports independent of the worktree's branch ([#344](https://github.com/tcorzo/fiuba-gestion-tp/issues/344)) ([848266c](https://github.com/tcorzo/fiuba-gestion-tp/commit/848266c5fb1c7661ca8f89ad242b44eff02e8ba4))
* **transport-windows:** backfill coordinates before NOT NULL constraint ([#325](https://github.com/tcorzo/fiuba-gestion-tp/issues/325)) ([6d2c319](https://github.com/tcorzo/fiuba-gestion-tp/commit/6d2c31908e2d0f05115f03f22df7ccfa439ce808))

## [0.2.3](https://github.com/tcorzo/fiuba-gestion-tp/compare/v0.2.2...v0.2.3) (2026-06-04)


### Features

* **cargo:** back link from carrier profile to cargo matches (Shipper) ([#296](https://github.com/tcorzo/fiuba-gestion-tp/issues/296)) ([fa3d1a2](https://github.com/tcorzo/fiuba-gestion-tp/commit/fa3d1a29d83bda6285b4c5992036c37ae3f9ab7a))
* **fulfilment:** geocoded addresses, pickup radius, and Haversine matching (US48 + US49 + US50) ([#264](https://github.com/tcorzo/fiuba-gestion-tp/issues/264)) ([1eb6387](https://github.com/tcorzo/fiuba-gestion-tp/commit/1eb6387040cae759b0eb715aa3b951a0939b768d))
* **fulfilment:** shipment detail page with role-aware actions (US39) ([#287](https://github.com/tcorzo/fiuba-gestion-tp/issues/287)) ([e7e58a3](https://github.com/tcorzo/fiuba-gestion-tp/commit/e7e58a3859918398a56136b46497bf062e8e719c))
* **marketplace:** us7 — cargo offer lifecycle + address-driven place utilities (fullstack) ([#308](https://github.com/tcorzo/fiuba-gestion-tp/issues/308)) ([56e5a30](https://github.com/tcorzo/fiuba-gestion-tp/commit/56e5a305e07a1b8a56a11f98888dae4fc1198bca))
* **notifications:** web realtime framework scaffold (Action Cable + Solid Cable) ([#303](https://github.com/tcorzo/fiuba-gestion-tp/issues/303)) ([9d8adf2](https://github.com/tcorzo/fiuba-gestion-tp/commit/9d8adf283b1d30466438ef15dac6fa9b3fcba876))
* **reviews:** shipper review display + avg rating in profile (fullstack) ([#299](https://github.com/tcorzo/fiuba-gestion-tp/issues/299)) ([1c9e419](https://github.com/tcorzo/fiuba-gestion-tp/commit/1c9e419c48023d172d6b62fa28555af93dde6b2a))
* **reviews:** us20 — Shipper creates Carrier review (fullstack) ([#300](https://github.com/tcorzo/fiuba-gestion-tp/issues/300)) ([19f72c0](https://github.com/tcorzo/fiuba-gestion-tp/commit/19f72c01a5fedc6e699ec64e5d0d8d4437905916))
* **reviews:** us26 — Carrier review display + avg rating in profile (fullstack) ([#302](https://github.com/tcorzo/fiuba-gestion-tp/issues/302)) ([cb430fc](https://github.com/tcorzo/fiuba-gestion-tp/commit/cb430fcf855b9a905361ce31773db4c912f0b2a6))
* **reviews:** us30 carrier→shipper review on delivered shipment ([#286](https://github.com/tcorzo/fiuba-gestion-tp/issues/286)) ([25fb10a](https://github.com/tcorzo/fiuba-gestion-tp/commit/25fb10a54a1c8404bdf01388d41038dc67ab7cc6))
* **shipments:** carrier shipment transitions (start_transit, deliver) — US18+US19 ([#297](https://github.com/tcorzo/fiuba-gestion-tp/issues/297)) ([bd8f351](https://github.com/tcorzo/fiuba-gestion-tp/commit/bd8f3517e19244ea60cc7668569346fa92691b83))
* **vehicles:** implemented soft deletion of vehicles ([#275](https://github.com/tcorzo/fiuba-gestion-tp/issues/275)) ([5e864d9](https://github.com/tcorzo/fiuba-gestion-tp/commit/5e864d9f12f1b28137d45bf894af836cf5128888))


### Bug Fixes

* **docs:** simplify geo ACs (US048-051) and restructure review stories ([#277](https://github.com/tcorzo/fiuba-gestion-tp/issues/277)) ([5afef58](https://github.com/tcorzo/fiuba-gestion-tp/commit/5afef580b854aa3a1b2899975adc6f14d84aec53))
* **technical debts:** vehicle plate edition and cargo price currency ([#298](https://github.com/tcorzo/fiuba-gestion-tp/issues/298)) ([a8d4f2c](https://github.com/tcorzo/fiuba-gestion-tp/commit/a8d4f2cf478ba5e1fa72cc393503e73d5ec236ee))

## [0.2.2](https://github.com/tcorzo/fiuba-gestion-tp/compare/v0.2.1...v0.2.2) (2026-05-28)


### Features

* **carrier:** offers inbox and acceptance flow — REQ-FE-00017 (US10) and REQ-BE-00024 (US12) ([#221](https://github.com/tcorzo/fiuba-gestion-tp/issues/221)) ([11991f1](https://github.com/tcorzo/fiuba-gestion-tp/commit/11991f131bc131d7ccab9477ed6a8ac3ee2701e0))
* **deploy:** bake VITE_API_BASE_URL into frontend build per env ([#270](https://github.com/tcorzo/fiuba-gestion-tp/issues/270)) ([e888c71](https://github.com/tcorzo/fiuba-gestion-tp/commit/e888c71beaedbf948ac2c94e55c19652dba779f1))
* **deploy:** wire FRONTEND_ORIGIN through SSM into the Rails container ([#268](https://github.com/tcorzo/fiuba-gestion-tp/issues/268)) ([64eb5fc](https://github.com/tcorzo/fiuba-gestion-tp/commit/64eb5fce53743e32a28ce01d73c389fa23928968))
* **fulfilment:** add Carrier and Shipper shipment list screens (US17) ([#258](https://github.com/tcorzo/fiuba-gestion-tp/issues/258)) ([13f8cc6](https://github.com/tcorzo/fiuba-gestion-tp/commit/13f8cc6f938d7f5e74b4d7ffb6ee171e573ff4bc))
* **fulfilment:** add Shipment index & detail endpoints (US17 + US39) ([#248](https://github.com/tcorzo/fiuba-gestion-tp/issues/248)) ([8f3ab60](https://github.com/tcorzo/fiuba-gestion-tp/commit/8f3ab605bc980bc3160cf6e1a24f25f0e887fbdc))
* **marketplace:** allow nullable destination on TransportWindow ([#227](https://github.com/tcorzo/fiuba-gestion-tp/issues/227)) ([d80bac6](https://github.com/tcorzo/fiuba-gestion-tp/commit/d80bac6ba4c64294fd9a2e6e424ee49ad7b30776))
* **payments:** add shipper payment flow with fake gateway (US8) ([#272](https://github.com/tcorzo/fiuba-gestion-tp/issues/272)) ([58f4a8b](https://github.com/tcorzo/fiuba-gestion-tp/commit/58f4a8b2dc24292eae999dab85140dea4d20c83d))


### Bug Fixes

* **fulfilment:** align Shipment FSM with ADR-012 and add Payment model ([#247](https://github.com/tcorzo/fiuba-gestion-tp/issues/247)) ([7d1ce0b](https://github.com/tcorzo/fiuba-gestion-tp/commit/7d1ce0b0bb3111e227992394f286dd9df097ce4b))

## [0.2.1](https://github.com/tcorzo/fiuba-gestion-tp/compare/v0.2.0...v0.2.1) (2026-05-23)


### Features

* **cargo:** cargo fullstack — modelo, endpoints + mis cargas UI (US27) ([#205](https://github.com/tcorzo/fiuba-gestion-tp/issues/205)) ([7e6b63e](https://github.com/tcorzo/fiuba-gestion-tp/commit/7e6b63e385101c553a64c2f62fe2ed4eacbf2c12))
* **infra:** add base AWS infrastructure with Terraform ([#143](https://github.com/tcorzo/fiuba-gestion-tp/issues/143)) ([d5c7ba7](https://github.com/tcorzo/fiuba-gestion-tp/commit/d5c7ba7f12b3e09d3baa6b8067b34f794b421da1))
* **landing:** two-voice committed palette with orchestrated motion ([#191](https://github.com/tcorzo/fiuba-gestion-tp/issues/191)) ([0df038b](https://github.com/tcorzo/fiuba-gestion-tp/commit/0df038bcb01ddda1efefe97121dd09ebaf2fd156))
* **profile:** user profile edition (US3) ([#177](https://github.com/tcorzo/fiuba-gestion-tp/issues/177)) ([fac61a9](https://github.com/tcorzo/fiuba-gestion-tp/commit/fac61a94237539e0cfef9f90b0c73d883dd60292))
* **shipper:** create offer wizard — US7 (REQ-FE-00015) ([#193](https://github.com/tcorzo/fiuba-gestion-tp/issues/193)) ([b4c7a7e](https://github.com/tcorzo/fiuba-gestion-tp/commit/b4c7a7ed690321f937cdc7a6f0a030d1176e318e))
* **team-performance:** measure throughput in completed User Stories via per-sprint ledger ([#207](https://github.com/tcorzo/fiuba-gestion-tp/issues/207)) ([378db7f](https://github.com/tcorzo/fiuba-gestion-tp/commit/378db7f7943af2419e2b17136ee5caa62b743ddc))
* **ui:** extend two-voice committed palette across auth, dashboard, carrier, public ([#192](https://github.com/tcorzo/fiuba-gestion-tp/issues/192)) ([2583227](https://github.com/tcorzo/fiuba-gestion-tp/commit/258322771486098c02b54ad57a5d854fbad3174e))


### Bug Fixes

* carrier details button, backlog and add sprint 2 docs ([#208](https://github.com/tcorzo/fiuba-gestion-tp/issues/208)) ([71d3fee](https://github.com/tcorzo/fiuba-gestion-tp/commit/71d3fee29bee783c9580c005e69ecc6b891203dc))
* **windows:** rename toggle copy to ocultar/mostrar ([#195](https://github.com/tcorzo/fiuba-gestion-tp/issues/195)) ([052ca98](https://github.com/tcorzo/fiuba-gestion-tp/commit/052ca98edc4241fc43b6e57f17fe6fdbe3ab2256))

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
