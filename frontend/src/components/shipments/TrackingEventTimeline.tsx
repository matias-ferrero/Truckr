import type { ShipmentState, TrackingEvent } from "../../api/shipments";
import { shipmentDetailContent as t } from "../../pages/shipments/shipmentDetailContent";
import { formatDateTime } from "../../lib/format-date";

function EventKindIcon({ kind }: { kind: string }) {
    if (kind === "shipment_accepted") {
        return (
            <svg width="11" height="11" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                <polyline points="2 9 6 13 14 3.5" />
            </svg>
        );
    }
    if (kind === "shipment_in_transit") {
        return (
            <svg width="11" height="11" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                <line x1="2" y1="8" x2="13" y2="8" />
                <polyline points="9 4 13 8 9 12" />
            </svg>
        );
    }
    if (kind === "shipment_delivered") {
        return (
            <svg width="11" height="11" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                <polyline points="1 9 5 13 10 3.5" />
                <polyline points="6 9 10 13 15 3.5" />
            </svg>
        );
    }
    if (kind === "shipment_cancelled" || kind === "payment_failed") {
        return (
            <svg width="10" height="10" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
                <line x1="4" y1="4" x2="12" y2="12" />
                <line x1="12" y1="4" x2="4" y2="12" />
            </svg>
        );
    }
    if (kind === "payment_escrowed") {
        return (
            <svg width="10" height="11" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                <rect x="3" y="8" width="10" height="6" rx="1.5" />
                <path d="M5.5 8V6.5a2.5 2.5 0 0 1 5 0V8" />
            </svg>
        );
    }
    return (
        <svg width="6" height="6" viewBox="0 0 8 8" fill="currentColor" stroke="none" aria-hidden="true">
            <circle cx="4" cy="4" r="3" />
        </svg>
    );
}

// Maps a status_change event to the canonical kind key used for icons/colors.
// When REQ-BE-00038 lands, events will carry dedicated kinds directly and
// this adapter can be removed.
function resolveKind(ev: { kind: string; to_status?: string | null }): string {
    if (ev.kind === "status_change" && ev.to_status) {
        return `shipment_${ev.to_status}`;
    }
    return ev.kind;
}

function eventLabel(ev: { kind: string; to_status?: string | null }): string {
    if (ev.kind === "status_change" && ev.to_status) {
        return t.tracking.statusChangeLabel[ev.to_status]
            ?? t.tracking.events[`shipment_${ev.to_status}`]
            ?? ev.to_status;
    }
    return t.tracking.events[ev.kind] ?? ev.kind;
}

type Props = {
    events: TrackingEvent[];
    shipmentState: ShipmentState;
};

export function TrackingEventTimeline({ events, shipmentState }: Props) {
    if (events.length === 0) {
        const contextualNote = t.tracking.emptyByState[shipmentState];
        return (
            <div className="trackingTimelineEmpty">
                <span className="trackingTimelineEmptyDot" aria-hidden="true" />
                <p className="trackingTimelineEmptyText">
                    {t.tracking.emptyDefault}
                    {contextualNote && (
                        <> <span className="trackingTimelineEmptyNote">{contextualNote}</span></>
                    )}
                </p>
            </div>
        );
    }

    const latestIndex = events.length - 1;

    return (
        <ol className="trackingTimeline" aria-label="Historial de eventos">
            {events.map((ev, i) => {
                const effectiveKind = resolveKind(ev);
                return (
                    <li
                        key={ev.id}
                        className="trackingTimelineItem"
                        data-kind={effectiveKind}
                        data-latest={i === latestIndex ? "" : undefined}
                        style={{ "--item-index": i } as React.CSSProperties}
                    >
                        <span className="trackingTimelineDot" aria-hidden="true">
                            <EventKindIcon kind={effectiveKind} />
                        </span>
                        <div className="trackingTimelineContent">
                            <span className="trackingTimelineKind">
                                {eventLabel(ev)}
                            </span>
                            <time className="trackingTimelineTime" dateTime={ev.occurred_at}>
                                {formatDateTime(ev.occurred_at)}
                            </time>
                        </div>
                    </li>
                );
            })}
        </ol>
    );
}
