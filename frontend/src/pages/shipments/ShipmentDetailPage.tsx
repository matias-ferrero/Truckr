import { useState, useEffect, useRef } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { useShipmentDetail } from "../../hooks/useShipmentDetail";
import { ShipmentStateChip } from "../../components/shipments/ShipmentStateChip";
import { PaymentStateChip } from "../../components/shipments/PaymentStateChip";
import { ShipmentActions } from "../../components/shipments/ShipmentActions";
import { TrackingEventTimeline } from "../../components/shipments/TrackingEventTimeline";
import { CarrierReviewForm } from "../../components/shipments/CarrierReviewForm";
import { ShipperReviewForm } from "../../components/shipments/ShipperReviewForm";
import { Button, buttonVariants } from "../../components/ui/button";
import { shipmentDetailContent as t } from "./shipmentDetailContent";
import { formatDateTime } from "../../lib/format-date";
import { formatCurrency } from "../../lib/format-currency";
import "../../styles/shipment-detail.css";

type Role = "carrier" | "shipper";
type Props = { role: Role };

function BannerIcon({ kind }: { kind: "to_pick_up" | "awaiting_payment" }) {
    if (kind === "to_pick_up") {
        return (
            <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                <line x1="8" y1="13" x2="8" y2="4" />
                <polyline points="4 8 8 4 12 8" />
                <line x1="3" y1="13" x2="13" y2="13" />
            </svg>
        );
    }
    return (
        <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
            <circle cx="8" cy="8" r="6" />
            <line x1="8" y1="5.5" x2="8" y2="8.5" />
            <circle cx="8" cy="11" r="0.75" fill="currentColor" stroke="none" />
        </svg>
    );
}

function milestoneAt(
    detail: { picked_up_at?: string | null; delivered_at?: string | null; tracking_events: Array<{ kind: string; occurred_at: string; to_status?: string | null }> },
    milestone: "picked_up" | "delivered",
): string | null {
    if (milestone === "picked_up" && detail.picked_up_at) return detail.picked_up_at;
    if (milestone === "delivered" && detail.delivered_at) return detail.delivered_at;

    const fromEvents = detail.tracking_events
        .slice()
        .reverse()
        .find((ev) => {
            if (milestone === "picked_up") {
                return ev.kind === "shipment_in_transit" || (ev.kind === "status_change" && ev.to_status === "in_transit");
            }
            return ev.kind === "shipment_delivered" || (ev.kind === "status_change" && ev.to_status === "delivered");
        });

    return fromEvents?.occurred_at ?? null;
}

function Skeleton() {
    return (
        <div className="shipmentDetailSkeleton" aria-busy="true" role="status" aria-label={t.skeleton.label}>
            <div className="container">
                <div className="shipmentDetailSkeletonBack" />
                <div className="shipmentDetailSkeletonTitle" />
                <div className="shipmentDetailSkeletonChips">
                    <div className="shipmentDetailSkeletonChip" />
                    <div className="shipmentDetailSkeletonChip" />
                </div>
                <div className="shipmentDetailSkeletonBody">
                    {Array.from({ length: 8 }).map((_, i) => (
                        <div key={i} className="shipmentDetailSkeletonField" />
                    ))}
                </div>
            </div>
        </div>
    );
}

export default function ShipmentDetailPage({ role }: Props) {
    const { id } = useParams<{ id: string }>();
    const numericId = id !== undefined ? Number(id) : NaN;
    const { state, reload, handleAction } = useShipmentDetail(numericId);
    const navigate = useNavigate();

    const [payDialogOpen, setPayDialogOpen] = useState(false);
    const payDialogRef = useRef<HTMLDialogElement>(null);

    const backHref = `/${role}/shipments`;

    useEffect(() => {
        const el = payDialogRef.current;
        if (!el) return;
        if (payDialogOpen) {
            el.showModal();
            const first = el.querySelector<HTMLElement>(
                'button:not([disabled]), [href], [tabindex]:not([tabindex="-1"])'
            );
            first?.focus();
        }
    }, [payDialogOpen]);

    if (state.status === "loading") return <Skeleton />;

    if (state.status === "not_found") {
        return (
            <main className="page shipmentDetailPage" id="main">
                <div className="container">
                    <div className="shipmentDetailNotFound">
                        <h1 className="shipmentDetailNotFoundTitle">{t.notfound.title}</h1>
                        <p className="shipmentDetailNotFoundLead">{t.notfound.lead}</p>
                        <Link to={backHref} className={buttonVariants({ variant: "outline", size: "sm" })}>
                            {t.notfound.cta}
                        </Link>
                    </div>
                </div>
            </main>
        );
    }

    if (state.status === "error") {
        return (
            <main className="page shipmentDetailPage" id="main">
                <div className="container">
                    <div className="shipmentDetailErrorPanel">
                        <h1 className="shipmentDetailErrorTitle">{t.error.title}</h1>
                        <p className="shipmentDetailErrorLead">{state.message}</p>
                        <Button variant="primary" onClick={reload}>{t.error.retry}</Button>
                    </div>
                </div>
            </main>
        );
    }

    const { detail, derived } = state;
    const shipmentSummary = `${detail.cargo.origin} → ${detail.cargo.destination}`;
    const pickedUpAt = milestoneAt(detail, "picked_up");
    const deliveredAt = milestoneAt(detail, "delivered");

    return (
        <main className={`page shipmentDetailPage shipmentDetailPage--${role}`} id="main">
            <div className="container">
                <Link to={backHref} className="shipmentDetailBack">{t.back}</Link>

                <header className="shipmentDetailHeader">
                    <div className="shipmentDetailTitleGroup">
                        <h1 className="shipmentDetailTitle">{t.title(detail.id)}</h1>
                        <div className="shipmentDetailChips">
                            <ShipmentStateChip state={detail.state} />
                            {detail.state !== "cancelled" && (
                                <PaymentStateChip paymentState={derived.paymentState} />
                            )}
                        </div>
                    </div>
                </header>

                <div aria-live="polite" aria-atomic="true">
                    {derived.compositeLabel && (
                        <div className={`shipmentDetailNextStep shipmentDetailNextStep--${derived.compositeLabel}`}>
                            <span className="shipmentDetailNextStepIcon">
                                <BannerIcon kind={derived.compositeLabel} />
                            </span>
                            <span className="shipmentDetailNextStepText">
                                {t.composite[derived.compositeLabel]}
                                {derived.compositeLabel === "awaiting_payment" && (
                                    <span className="shipmentDetailNextStepMeta"> · {formatCurrency(detail.amount_cents, detail.currency)}</span>
                                )}
                            </span>
                            {derived.compositeLabel === "awaiting_payment" && role === "shipper" && (
                                <button
                                    type="button"
                                    className="shipmentDetailNextStepCta"
                                    onClick={() => setPayDialogOpen(true)}
                                >
                                    {derived.payLabel === "retry_payment" ? t.actions.retry_payment : t.composite.awaiting_payment_cta}
                                    <span aria-hidden="true"> →</span>
                                </button>
                            )}
                        </div>
                    )}
                </div>

                {payDialogOpen && (
                    <dialog
                        className="confirmDialog"
                        ref={payDialogRef}
                        data-action="pay"
                        aria-labelledby="payConfirmDetailTitle"
                        onCancel={(e) => { e.preventDefault(); setPayDialogOpen(false); }}
                    >
                        <div className="confirmDialogBody">
                            <div className="confirmDialogPaymark" aria-hidden="true">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                                    <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
                                    <polyline points="9 12 11 14 15 10" />
                                </svg>
                            </div>
                            <h2 className="confirmDialogTitle" id="payConfirmDetailTitle">
                                {t.confirm.title}
                            </h2>
                            <p className="confirmDialogRoute">{shipmentSummary}</p>
                            <p className="confirmDialogLead">{t.actions.pay}</p>
                            <p className="confirmDialogText">
                                {(t.confirm.consequence as Record<string, string>)["pay"]}
                            </p>
                            <div className="confirmDialogActions">
                                <Button variant="ghost" onClick={() => setPayDialogOpen(false)}>
                                    {t.actions.cancel_dialog}
                                </Button>
                                <Button
                                    variant="primary"
                                    className="confirmDialogConfirmBtn"
                                    onClick={() => {
                                        setPayDialogOpen(false);
                                        navigate(`/shipper/shipments/${numericId}/pay`);
                                    }}
                                >
                                    Confirmar
                                </Button>
                            </div>
                        </div>
                    </dialog>
                )}

                <section className="shipmentDetailBody" aria-label="Datos del envío">
                    <dl className="shipmentDetailGrid">
                        <div>
                            <dt>{t.fields.origin}</dt>
                            <dd>{detail.cargo.origin}</dd>
                        </div>
                        <div>
                            <dt>{t.fields.destination}</dt>
                            <dd>{detail.cargo.destination}</dd>
                        </div>
                        <div>
                            <dt>{t.fields.amount}</dt>
                            <dd className="shipmentDetailAmount">
                                {formatCurrency(detail.amount_cents, detail.currency)}
                            </dd>
                        </div>
                        <div>
                            <dt>{t.fields.description}</dt>
                            <dd>{detail.cargo.description}</dd>
                        </div>
                        <div>
                            <dt>{t.fields.weight}</dt>
                            <dd>{detail.cargo.weight_kg} kg</dd>
                        </div>
                        <div>
                            <dt>{t.fields.vehicle}</dt>
                            <dd>{detail.vehicle.plate}</dd>
                        </div>
                        {detail.counterparty && (
                            <div>
                                <dt>{t.counterparty[role]}</dt>
                                <dd>
                                    {detail.counterparty.kind === "shipper"
                                        ? (
                                            <Link
                                                to={`/shippers/${detail.counterparty.id}`}
                                                className="shipmentCounterpartyLink"
                                            >
                                                {detail.counterparty.display_name}
                                            </Link>
                                        )
                                        : detail.counterparty.display_name}
                                </dd>
                            </div>
                        )}
                        <div>
                            <dt>{t.fields.created_at}</dt>
                            <dd>{formatDateTime(detail.created_at)}</dd>
                        </div>
                        {pickedUpAt && (
                            <div>
                                <dt>{t.fields.picked_up_at}</dt>
                                <dd>{formatDateTime(pickedUpAt)}</dd>
                            </div>
                        )}
                        {deliveredAt && (
                            <div>
                                <dt>{t.fields.delivered_at}</dt>
                                <dd>{formatDateTime(deliveredAt)}</dd>
                            </div>
                        )}
                    </dl>

                    {detail.counterparty_contact && (
                        <div className="shipmentDetailContactSection" aria-label={`${t.contact.sectionTitle}: ${t.counterparty[role]}`}>
                            <h2 className="shipmentDetailContactTitle">
                                {t.contact.sectionTitle}
                            </h2>
                            <dl className="shipmentDetailGrid">
                                <div>
                                    <dt>{t.fields.contact_name}</dt>
                                    <dd>{detail.counterparty_contact.full_name}</dd>
                                </div>
                                <div>
                                    <dt>{t.fields.contact_email}</dt>
                                    <dd>{detail.counterparty_contact.email}</dd>
                                </div>
                                {detail.counterparty_contact.phone && (
                                    <div>
                                        <dt>{t.fields.contact_phone}</dt>
                                        <dd>{detail.counterparty_contact.phone}</dd>
                                    </div>
                                )}
                            </dl>
                        </div>
                    )}

                    {role === "carrier" && detail.payout && (
                        <div className="shipmentDetailContactSection" aria-label={t.payout.sectionTitle}>
                            <div className="shipmentDetailSectionHeading">
                                <h2 className="shipmentDetailContactTitle">
                                    {t.payout.sectionTitle}
                                </h2>
                                <span className={`carrierPayoutsState carrierPayoutsState--${detail.payout.state}`}>
                                    {t.payout.states[detail.payout.state]}
                                </span>
                            </div>
                            <dl className="shipmentDetailGrid">
                                <div>
                                    <dt>{t.payout.gross}</dt>
                                    <dd>{formatCurrency(detail.payout.gross_amount_cents, detail.payout.currency)}</dd>
                                </div>
                                <div>
                                    <dt>{t.payout.commission} ({(parseFloat(detail.payout.commission_rate) * 100).toFixed(0)}%)</dt>
                                    <dd className="shipmentDetailPayoutCommission">
                                        - {formatCurrency(detail.payout.commission_cents, detail.payout.currency)}
                                    </dd>
                                </div>
                                <div>
                                    <dt>{t.payout.net}</dt>
                                    <dd className="shipmentDetailPayoutNet">
                                        {formatCurrency(detail.payout.amount_cents, detail.payout.currency)}
                                    </dd>
                                </div>
                                {detail.payout.paid_at && (
                                    <div>
                                        <dt>{t.payout.paid_at}</dt>
                                        <dd>{formatDateTime(detail.payout.paid_at)}</dd>
                                    </div>
                                )}
                            </dl>
                        </div>
                    )}
                </section>


                <section className="shipmentTimelineSection">
                    <h2 className="shipmentTimelineTitle">
                        {t.tracking.sectionTitle}
                        {detail.tracking_events.length > 0 && (
                            <span className="shipmentTimelineCount" aria-label={`${detail.tracking_events.length} eventos`}>
                                {detail.tracking_events.length}
                            </span>
                        )}
                    </h2>
                    <TrackingEventTimeline events={detail.tracking_events} shipmentState={detail.state} />
                    {role === "carrier" && (
                        <ShipmentActions
                            available_actions={detail.available_actions}
                            payLabel={derived.payLabel}
                            isActing={derived.isActing}
                            actionError={derived.actionError}
                            onAction={handleAction}
                            shipmentSummary={shipmentSummary}
                        />
                    )}
                </section>

                {/* US20 / US30 — delivered-shipment review forms. Shippers can review
                    carriers and carriers can review shippers. Each form hydrates
                    straight into its read-only state when the backend already
                    returned the corresponding review, and flips there itself after
                    a successful submit. */}
                {role === "shipper" && detail.state === "delivered" && (
                    <section className="shipmentReviewSection" aria-label={t.review.shipperSectionLabel}>
                        <ShipperReviewForm
                            shipmentId={detail.id}
                            existingReview={detail.shipper_review ?? null}
                            onCreated={() => {
                                window.dispatchEvent(new Event("truckr:shipment-updated"));
                            }}
                        />
                    </section>
                )}

                {role === "carrier" && detail.state === "delivered" && (
                    <section className="shipmentReviewSection" aria-label={t.review.carrierSectionLabel}>
                        <CarrierReviewForm
                            shipmentId={detail.id}
                            existingReview={detail.carrier_review ?? null}
                            onCreated={() => {
                                window.dispatchEvent(new Event("truckr:shipment-updated"));
                            }}
                        />
                    </section>
                )}

                {/* Anchor for the map component (US51 / AC5). Hidden until the map feature lands. */}
                <div id="shipment-tracking-map" hidden aria-hidden="true" />

            </div>
        </main>
    );
}
