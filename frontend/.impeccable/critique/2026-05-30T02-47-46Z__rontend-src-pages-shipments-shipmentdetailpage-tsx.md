---
target: ShipmentDetailPage + ShipmentActions + TrackingEventTimeline
total_score: 29
p0_count: 1
p1_count: 2
timestamp: 2026-05-30T02-47-46Z
slug: rontend-src-pages-shipments-shipmentdetailpage-tsx
---
## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Skeleton and chips solid; action spinner generic, no post-mutation success signal |
| 2 | Match System / Real World | 3 | Labels mostly clear; composite labels not self-evident without UI context |
| 3 | User Control and Freedom | 3 | Back-link and modal cancel exist; no auto-navigate after successful action |
| 4 | Consistency and Standards | 3 | Follows patterns; confirmDialog CSS relies on globally-imported carrier.css |
| 5 | Error Prevention | 4 | Confirmation modal for transitions; safe-by-delegation prevents impossible buttons |
| 6 | Recognition Rather Than Recall | 4 | All data in dl grid; chips summarize; counterparty and vehicle visible |
| 7 | Flexibility and Efficiency | 2 | No keyboard affordances; no expert shortcuts for repeat Carriers |
| 8 | Aesthetic and Minimalist Design | 2 | Timeline completely unstyled; composite label identical to state chips |
| 9 | Error Recovery | 3 | Retry on page load error; action error inline; no remediation guidance |
| 10 | Help and Documentation | 2 | No contextual guidance; map placeholder dead space; composite labels unexplained |
| **Total** | | **29/40** | **Good** |

## Anti-Patterns Verdict
Borderline AI slop. Competent scaffolding with clean tokens and no absolute-ban violations, but clinical and flat for the most important Carrier action screen. No detector binary available; manual scan confirmed no CSS anti-patterns. **Critical: TrackingEventTimeline classes have zero CSS rules.**

## Priority Issues
- [P0] Timeline renders completely unstyled — zero CSS rules for .trackingTimeline, .trackingTimelineItem, .trackingTimelineTime, .trackingTimelineKind
- [P1] Composite label visually indistinguishable from state chips — same pill shape, same weight
- [P1] Confirmation modal shows action label only — no shipment context (route, amount)
- [P2] Action error shows raw message — no remediation guidance
- [P2] Map placeholder pushes actions below fold on mobile

## counterparty_contact not rendered
Field present in ShipmentDetail type but not displayed in page. After escrow, Shipper cannot see Carrier contact details.
