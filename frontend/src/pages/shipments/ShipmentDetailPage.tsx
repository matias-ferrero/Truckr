import { useState, useEffect, useRef } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { useShipmentDetail } from "../../hooks/useShipmentDetail";
import { ShipmentStateChip } from "../../components/shipments/ShipmentStateChip";
import { PaymentStateChip } from "../../components/shipments/PaymentStateChip";
import { PrimaryActionCard } from "../../components/shipments/PrimaryActionCard";
import { TrackingEventTimeline } from "../../components/shipments/TrackingEventTimeline";
import { CarrierReviewForm } from "../../components/shipments/CarrierReviewForm";
import { ShipperReviewForm } from "../../components/shipments/ShipperReviewForm";
import { ShipmentMap, toLatLng } from "../../components/ShipmentMap";
import { OpenInGmapsButton } from "../../components/OpenInGmapsButton";
import { Button, buttonVariants } from "../../components/ui/button";
import type { Review } from "../../api/reviews";
import { shipmentDetailContent as t } from "./shipmentDetailContent";
import { formatDateTime } from "../../lib/format-date";
import { formatCurrency } from "../../lib/format-currency";
import "../../styles/shipment-detail.css";

type Role = "carrier" | "shipper";
type Props = { role: Role };

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
                <div className="shipmentDetailSkeletonLayout">
                    <div className="shipmentDetailSkeletonRail">
                        <div className="shipmentDetailSkeletonCard" />
                        <div className="shipmentDetailSkeletonCard" />
                    </div>
                    <div className="shipmentDetailSkeletonBody">
                        {Array.from({ length: 8 }).map((_, i) => (
                            <div key={i} className="shipmentDetailSkeletonField" />
                        ))}
                    </div>
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

    // Review modal (shipment-detail v2 §5). The rail card is the entry point;
    // the form itself opens in a focused dialog. `localReview` flips the rail
    // to the done card after submit without a full page reload.
    const [reviewDialogOpen, setReviewDialogOpen] = useState(false);
    const [localReview, setLocalReview] = useState<Review | null>(null);
    const reviewDialogRef = useRef<HTMLDialogElement>(null);

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

    useEffect(() => {
        const el = reviewDialogRef.current;
        if (!el) return;
        if (reviewDialogOpen) {
            el.showModal();
            const first = el.querySelector<HTMLElement>(
                'button:not([disabled]), [href], [tabindex]:not([tabindex="-1"])'
            );
            first?.focus();
        }
    }, [reviewDialogOpen]);

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

    const viewerReview = (role === "shipper" ? detail.shipper_review : detail.carrier_review) ?? localReview;

    // US51 — pins come from the Cargo (pickup = origin, delivery = destination),
    // not the TransportWindow: once the trip starts the carrier goes to where the
    // load is. Coordinates are state-independent, so the map shows in every state.
    const originPin = toLatLng(detail.cargo.pickup_lat, detail.cargo.pickup_lng, detail.cargo.origin);
    const destinationPin = toLatLng(detail.cargo.delivery_lat, detail.cargo.delivery_lng, detail.cargo.destination);

    // State-aware navigation emphasis (v2 §4) — the one deliberate role-aware
    // exception in the otherwise role-agnostic main column. While `accepted`+paid
    // the carrier is driving to the pickup; while `in_transit`, to the delivery.
    // Shippers always get the full origin→destination route (tracking, not driving).
    const paid = derived.paymentState === "paid";
    const carrierNav: { label: string; ariaLabel: string; destination: NonNullable<typeof originPin> } | null =
        role === "carrier" && originPin && destinationPin
            ? detail.state === "accepted" && paid
                ? { label: t.map.navToPickup, ariaLabel: t.map.navToPickupAria(detail.cargo.origin), destination: originPin }
                : detail.state === "in_transit"
                    ? { label: t.map.navToDelivery, ariaLabel: t.map.navToDeliveryAria(detail.cargo.destination), destination: destinationPin }
                    : null
            : null;

    const reputationHref = detail.counterparty
        ? detail.counterparty.kind === "carrier"
            ? `/carriers/${detail.counterparty.id}`
            : `/shippers/${detail.counterparty.id}`
        : null;

    const ReviewFormForRole = role === "shipper" ? ShipperReviewForm : CarrierReviewForm;
    const reviewSectionLabel = role === "shipper" ? t.review.shipperSectionLabel : t.review.carrierSectionLabel;

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

                <div className="shipmentDetailLayout">
                    {/* Rail first in DOM: the primary action is the page's most
                        valuable content — first in tab order, first on mobile. */}
                    <aside className="shipmentDetailRail" aria-label={t.rail.regionLabel}>
                        {/* Carrier money moment (prd §3, peak-end): on a delivered
                            shipment the payout leads the rail — "¿cuándo cobro?" is
                            answered before we ask for a review. Falls back to an
                            explicit in-process card when the payout row hasn't
                            landed yet, never silence. */}
                        {role === "carrier" && detail.state === "delivered" && (
                            detail.payout ? (
                                <section className="shipmentDetailRailCard shipmentDetailPayoutCard" aria-label={t.payout.sectionTitle}>
                                    <div className="shipmentDetailSectionHeading">
                                        <h2 className="shipmentDetailContactTitle">
                                            {t.payout.sectionTitle}
                                        </h2>
                                        <span className={`carrierPayoutsState carrierPayoutsState--${detail.payout.state}`}>
                                            {t.payout.states[detail.payout.state]}
                                        </span>
                                    </div>
                                    <dl className="shipmentDetailRailList">
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
                                </section>
                            ) : (
                                <section className="primaryActionCard primaryActionCard--status" aria-label={t.payout.sectionTitle}>
                                    <div>
                                        <p className="primaryActionCard__eyebrow">{t.payout.pending.eyebrow}</p>
                                        <h2 className="primaryActionCard__headline">{t.payout.pending.headline}</h2>
                                        <p className="primaryActionCard__lead">{t.payout.pending.lead}</p>
                                    </div>
                                </section>
                            )
                        )}

                        <PrimaryActionCard
                            role={role}
                            state={detail.state}
                            paymentState={derived.paymentState}
                            payLabel={derived.payLabel}
                            amountLabel={formatCurrency(detail.amount_cents, detail.currency)}
                            hasReview={viewerReview !== null}
                            available_actions={detail.available_actions}
                            isActing={derived.isActing}
                            actionError={derived.actionError}
                            onAction={handleAction}
                            onPay={() => setPayDialogOpen(true)}
                            onOpenReview={() => setReviewDialogOpen(true)}
                            shipmentSummary={shipmentSummary}
                        />

                        {/* US20 / US30 — once the viewer's review exists (from the
                            backend or just submitted in the modal) the read-only
                            card takes the rail's primary slot. */}
                        {detail.state === "delivered" && viewerReview && !reviewDialogOpen && (
                            <section className="shipmentReviewSection" aria-label={reviewSectionLabel}>
                                <ReviewFormForRole
                                    shipmentId={detail.id}
                                    existingReview={viewerReview}
                                />
                            </section>
                        )}

                        {detail.counterparty_contact && (
                            <section className="shipmentDetailRailCard shipmentDetailContactSection" aria-label={`${t.contact.sectionTitle}: ${t.counterparty[detail.counterparty?.kind ?? (role === "shipper" ? "carrier" : "shipper")]}`}>
                                <h2 className="shipmentDetailContactTitle">
                                    {t.contact.sectionTitle}
                                </h2>
                                <dl className="shipmentDetailRailList">
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
                                {/* Link-only counterparty reputation (v2 §6) — both sides,
                                    deep-linking to the public profile with reviews. */}
                                {reputationHref && detail.counterparty && (
                                    <Link to={reputationHref} className="shipmentReputationLink">
                                        {t.reputation[detail.counterparty.kind]}
                                        <span aria-hidden="true"> →</span>
                                    </Link>
                                )}
                            </section>
                        )}
                    </aside>

                    <div className="shipmentDetailMain">
                        {/* US51 / REQ-FE-00028 — route map + Google Maps deep-links. Keeps
                            the `shipment-tracking-map` anchor from US39 (AC7); the
                            buttons stay usable even if the map fails to load (AC9). */}
                        <section
                            id="shipment-tracking-map"
                            className="shipmentMapSection"
                            aria-labelledby="shipment-map-heading"
                        >
                            <h2 id="shipment-map-heading" className="shipmentMapTitle">
                                {t.map.sectionTitle}
                            </h2>
                            <ShipmentMap origin={originPin} destination={destinationPin} />
                            {originPin && destinationPin && (
                                <div className="shipmentMapActions">
                                    {carrierNav && (
                                        <OpenInGmapsButton
                                            destination={carrierNav.destination}
                                            label={carrierNav.label}
                                            ariaLabel={carrierNav.ariaLabel}
                                            variant="primary"
                                        />
                                    )}
                                    <OpenInGmapsButton
                                        origin={originPin}
                                        destination={destinationPin}
                                        label={t.map.openRoute}
                                        ariaLabel={t.map.openRouteAria(detail.cargo.origin, detail.cargo.destination)}
                                    />
                                </div>
                            )}
                        </section>

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
                                        {/* Label by the counterparty's kind, not the viewer's role —
                                            a shipper's counterparty is the Transportista. */}
                                        <dt>{t.counterparty[detail.counterparty.kind]}</dt>
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
                        </section>
                    </div>
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
                                {t.confirm.payTitle}
                            </h2>
                            <p className="confirmDialogRoute">{shipmentSummary}</p>
                            <p className="confirmDialogPayAmount">{formatCurrency(detail.amount_cents, detail.currency)}</p>
                            <p className="confirmDialogText">
                                {t.confirm.payReassurance}
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
                                    {t.confirm.payCta(formatCurrency(detail.amount_cents, detail.currency))}
                                </Button>
                            </div>
                        </div>
                    </dialog>
                )}

                {/* US20 / US30 in a focused modal (v2 §5) — same <dialog> pattern as
                    the pay confirmation. The form flips itself to its read-only
                    state after submit; closing then hands the done card to the rail. */}
                {reviewDialogOpen && (
                    <dialog
                        className="confirmDialog reviewDialog"
                        ref={reviewDialogRef}
                        aria-label={reviewSectionLabel}
                        onCancel={(e) => { e.preventDefault(); setReviewDialogOpen(false); }}
                    >
                        <div className="confirmDialogBody reviewDialogBody">
                            <ReviewFormForRole
                                shipmentId={detail.id}
                                existingReview={localReview}
                                onCreated={(review) => {
                                    setLocalReview(review);
                                    window.dispatchEvent(new Event("truckr:shipment-updated"));
                                }}
                            />
                            <div className="confirmDialogActions reviewDialogActions">
                                <Button variant="ghost" onClick={() => setReviewDialogOpen(false)}>
                                    {t.rail.review.dialogClose}
                                </Button>
                            </div>
                        </div>
                    </dialog>
                )}

            </div>
        </main>
    );
}
