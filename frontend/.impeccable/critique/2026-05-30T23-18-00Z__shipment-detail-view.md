---
target: shipment detail view
total_score: 28
p0_count: 0
p1_count: 2
timestamp: 2026-05-30T23-18-00Z
slug: shipment-detail-view
---
## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Success flash (0.6% scale pulse) is imperceptible |
| 2 | Match System / Real World | 4 | Excellent freight language throughout |
| 3 | User Control and Freedom | 3 | No post-action undo (acceptable for FSM); Esc on dialog works |
| 4 | Consistency and Standards | 3 | Contact section heading duplicates the dt role label above it |
| 5 | Error Prevention | 3 | Confirm dialog shows action label, not consequence |
| 6 | Recognition Rather Than Recall | 3 | All actions visible and labeled |
| 7 | Flexibility and Efficiency | 2 | No keyboard shortcuts; sticky mobile action zone is a genuine win |
| 8 | Aesthetic and Minimalist Design | 3 | Amount field position 8 contradicts its visual importance |
| 9 | Error Recovery | 3 | Inline errors good; raw API message could surface to users |
| 10 | Help and Documentation | 1 | No contextual help; emptyByState notes are the only guidance |
| **Total** | | **28/40** | **Good** |

## Anti-Patterns Verdict

Not AI slop. Two-voice palette with absolute oklch values bypassing the carrier.css cascade, dominant-vs-detail-voice split on decorative elements, sticky mobile action zone — these are system-thinking decisions, not reflexes. Deterministic scan: 0 findings.

## Overall Impression

Strong bones. Role-voice system is real. The biggest missed opportunity is at the highest-stakes moment: the confirm dialog gives no consequence context, just echoes the action label. Fix that and H&D, and this reaches Very Good.

## What's Working

1. Two-voice role differentiation is crisp — sky/saffron signals persona at a glance.
2. Sticky action zone on mobile is a genuine thumb-zone win for carriers on the road.
3. `emptyByState` timeline notes eliminate "is something broken?" confusion.

## Priority Issues

**[P1] Amount field buried at position 8 in data grid** — Amount is the financial anchor; it's the last field in an 8-field grid. Display treatment shouts importance; position buries it. Fix: promote to position 2-3, or surface near the title. `/layout`

**[P1] Confirm dialog provides no consequence copy** — Dialog renders the action label as the confirmation question. Users confirm the action name, not the consequence. Fix: add `consequence` key per action in `shipmentDetailContent.confirm`. `/clarify`

**[P2] Contact section heading duplicates dt label** — h2 says "Transportista" immediately below a dt labeled "Transportista". Fix: change to "Datos de contacto". `/clarify`

**[P2] Success feedback imperceptible** — `action-success` animation is 0.6% scale pulse. Invisible in practice. Fix: brief background color flash to brand-success tint. `/animate`

## Persona Red Flags

**Casey (Carrier on the road)**: Sticky action zone solves the reach problem. But after tapping "Iniciar transporte", the 0.6% scale feedback gives zero confidence the tap registered. Likely to tap again, triggering a double-confirm.

**Sam (Accessibility)**: Focus order is clean. Confirm dialog handles Esc. Risk: `<time dateTime={ev.occurred_at}>` will have VoiceOver announce the ISO string AND the human-formatted text on some readers.

## Minor Observations

- `fields.counterparty` in content file is dead code.
- `aria-label` on contact section uses em dash ("Datos de contacto — Transportista"); should be colon.
- `awaiting_payment` banner doesn't show the amount; shipper must scroll the full grid to find it before paying.
- `--accent` dot color for `shipment_accepted` is undocumented outside the design system.
