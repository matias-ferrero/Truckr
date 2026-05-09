---
tag: REQ-BE-00016
title: Seguros — integración con proveedor (API + esquema de coberturas)
priority: P3
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/96
author: Claude Code
github_issue: 96
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtCPw
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:24:36.113724+00:00Z
labels:
- REQ
- BE
- insurance
- post-mvp
- us25
---

## Summary

Setup base de la integración con un proveedor de seguros: cliente HTTP, autenticación, esquema de coberturas disponibles. Primera rebanada de US25, equivalente a `REQ-BE-00006` (MP) pero para insurance. Permite que las rebanadas siguientes (cotización, contratación, siniestros) se construyan sobre una base estable.

## Problem Statement

US25 ("Gestión de Seguros") agrupa todo el ciclo: ofertar, cotizar, contratar, emitir póliza, gestionar siniestros. La WBS (`docs/artifacts/wbs.typ` § 4.x) ya identifica 5 sub-bloques. Sin un cliente HTTP funcional contra un proveedor real, todo lo demás es código de placeholder.

Decisiones a tomar en este issue:
- ¿Qué proveedor? (decisión: arrancar con un mock interno + dejar la abstracción lista para integrar uno real).
- ¿Qué coberturas se ofrecen? (catálogo curado: básica, intermedia, full, definidas por valor declarado y distancia).
- ¿Cómo se identifica una póliza? (numerador local + ID externo del proveedor).

## Expected Behavior

- Modelo `InsuranceProvider`: `name`, `api_base_url`, `enabled`, `credentials_ref` (apunta a Rails credentials).
- Modelo `InsuranceCoverage`: `provider_id`, `name`, `description`, `min_value`, `max_value`, `base_premium_pct` (decimal). Catálogo seedeable.
- Cliente HTTP (`InsuranceClient`) con interfaz: `quote(value, distance)`, `contract(quote_id, customer_data)`, `report_claim(policy_id, payload)`.
- Implementación inicial: mock determinístico (genera primas según una fórmula simple). Documentado como mock.
- Logging tagged `Rails.logger.tagged("insurance")`.
- ENV: `INSURANCE_PROVIDER=mock` por default.

## Technical Notes

- **Abstracción**: el `InsuranceClient` debe ser inyectable (`Rails.configuration.insurance_client`) para que tests usen un fake y cuando se conecte un proveedor real solo cambie la implementación.
- **Mock determinístico**: la prima = `value * 0.02 + distance_km * 0.01` con distintos multiplicadores por cobertura. Útil para demos.
- **No exponer al frontend todavía**: este issue es BE-only. El consumo por UI vive en los issues hermanos.

## Related

- US fuente: US25.
- WBS: `docs/artifacts/wbs.typ` § 4.1 (Integración con Proveedor).
- Hermanos: `REQ-BE-00017` (cotización), `REQ-BE-00018` (contratación + póliza), `REQ-BE-00019` (siniestros).

## Acceptance Criteria

- [ ] Modelos `InsuranceProvider`, `InsuranceCoverage` con migración + seeds.
- [ ] `InsuranceClient` con interfaz e implementación mock.
- [ ] Configuración por ENV.
- [ ] Logging tagged.
- [ ] Tests con la mock implementation.
- [ ] README en `docs/05-appendices/insurance.md` describe la abstracción.
