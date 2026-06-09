import { useCallback, useEffect, useRef, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { cancelCargo, getCargo } from "./api";
import type { Cargo, CargoOffer } from "../../types/Cargo";
import { cargosContent } from "./cargosContent";
import { formatRoute } from "../../lib/format-place";
import { formatDistance } from "../../lib/format-distance";
import { Alert } from "../../components/ui/alert";
import { Button } from "../../components/ui/button";
import CargoMapPreview from "./CargoMapPreview";

const t = cargosContent.detail;

const arsFormatter = new Intl.NumberFormat("es-AR", {
    style: "currency",
    currency: "ARS",
    currencyDisplay: "code",
    maximumFractionDigits: 0,
});

function formatDate(iso: string): string {
    return new Date(iso).toLocaleDateString("es-AR", {
        day: "2-digit",
        month: "2-digit",
        year: "2-digit",
    });
}

function formatDateTime(iso: string): string {
    return new Date(iso).toLocaleString("es-AR", {
        day: "2-digit",
        month: "2-digit",
        year: "2-digit",
        hour: "2-digit",
        minute: "2-digit",
    });
}

type CargoState =
    | { status: "loading" }
    | { status: "ready"; cargo: Cargo }
    | { status: "error"; message: string };

export default function CargoDetail() {
    const params = useParams<{ id: string }>();
    const cargoId = Number(params.id);

    const [state, setState] = useState<CargoState>({ status: "loading" });
    const [cancelOpen, setCancelOpen] = useState(false);
    const [cancelReason, setCancelReason] = useState("");
    const [cancelling, setCancelling] = useState(false);
    const [cancelError, setCancelError] = useState<string | null>(null);
    const dialogRef = useRef<HTMLDialogElement>(null);
    const dismissCancelRef = useRef<HTMLButtonElement>(null);

    const loadCargo = useCallback(async () => {
        setState({ status: "loading" });
        try {
            const cargo = await getCargo(cargoId);
            setState({ status: "ready", cargo });
        } catch (e) {
            setState({ status: "error", message: (e as Error).message });
        }
    }, [cargoId]);

    useEffect(() => {
        loadCargo();
    }, [loadCargo]);

    useEffect(() => {
        const dialog = dialogRef.current;
        if (!dialog) return;
        if (cancelOpen && !dialog.open) {
            dialog.showModal();
            // Land focus on the safe (non-destructive) action, not the
            // trigger — the native <dialog> already traps Tab + handles Esc.
            dismissCancelRef.current?.focus();
        } else if (!cancelOpen && dialog.open) {
            dialog.close();
        }
    }, [cancelOpen]);

    async function handleCancel() {
        setCancelling(true);
        setCancelError(null);
        try {
            await cancelCargo(cargoId, cancelReason.trim() || undefined);
            setCancelOpen(false);
            await loadCargo();
        } catch {
            setCancelError(t.cancelDialog.error);
        } finally {
            setCancelling(false);
        }
    }

    if (state.status === "loading") {
        return (
            <main className="page" id="main">
                <div className="container">
                    <p className="sectionLead" role="status" aria-busy="true">
                        {t.loadingLabel}
                    </p>
                </div>
            </main>
        );
    }

    if (state.status === "error") {
        return (
            <main className="page" id="main">
                <div className="container">
                    <div className="errorPanel" role="alert">
                        <p>
                            {t.loadError}: {state.message}
                        </p>
                        <button
                            className="button buttonGhost"
                            type="button"
                            onClick={loadCargo}
                        >
                            {t.retry}
                        </button>
                    </div>
                </div>
            </main>
        );
    }

    const { cargo } = state;
    const acceptedOffer = cargo.cargo_offers.find((o) => o.status === "accepted");

    return (
        <main className="page" id="main">
            <div className="container">
                <Link to="/shipper/cargos" className="backLink">
                    {t.backToList}
                </Link>

                <header className="detailHeader">
                    <div>
                        <h1 className="sectionTitle">
                            {formatRoute(
                                { locality: cargo.pickup_locality, admin_area: cargo.pickup_admin_area },
                                { locality: cargo.delivery_locality, admin_area: cargo.delivery_admin_area },
                                t.summary.openDestinationLabel,
                            )}
                        </h1>
                        <span
                            className={`statusBadge ${
                                cargosContent.statusBadgeClass[cargo.status] ??
                                "pendiente"
                            }`}
                        >
                            {cargosContent.statusLabel[cargo.status] ?? cargo.status}
                        </span>
                    </div>
                    {cargo.editable && (
                        <div className="cardActions">
                            <Link
                                to={`/shipper/cargos/${cargo.id}/matches`}
                                className="button buttonPrimary"
                            >
                                {t.searchCarriersCta}
                            </Link>
                            <Link
                                to={`/shipper/cargos/${cargo.id}/edit`}
                                className="button buttonGhost"
                            >
                                {t.editCta}
                            </Link>
                            <Button
                                variant="danger"
                                onClick={() => {
                                    setCancelError(null);
                                    setCancelOpen(true);
                                }}
                            >
                                {t.cancelCta}
                            </Button>
                        </div>
                    )}
                </header>

                {cargo.status === "cancelled" && (
                    <Alert tone="info" role="status">
                        {cargo.cancelled_at
                            ? t.cancelledAt(formatDate(cargo.cancelled_at))
                            : t.cancelledBadge}
                    </Alert>
                )}

                <section
                    className="detailSection"
                    aria-labelledby="cargo-summary-title"
                >
                    <h2 id="cargo-summary-title" className="sectionSubtitle">
                        {t.sections.summary}
                    </h2>
                    <p className="cargoCardDescription">{cargo.cargo_description}</p>
                    <dl className="detailGrid">
                        <div>
                            <dt>{t.summary.pickup}</dt>
                            <dd>{cargo.pickup_address}</dd>
                        </div>
                        <div>
                            <dt>{t.summary.delivery}</dt>
                            <dd>{cargo.delivery_address}</dd>
                        </div>
                        <div>
                            <dt>{t.summary.pickupWindow}</dt>
                            <dd>
                                {formatDateTime(cargo.pickup_window_start)}
                                {" – "}
                                {formatDateTime(cargo.pickup_window_end)}
                            </dd>
                        </div>
                        <div>
                            <dt>{t.summary.weight}</dt>
                            <dd>
                                {cargo.weight_kg} {t.summary.weightUnit}
                            </dd>
                        </div>
                        <div>
                            <dt>{t.summary.volume}</dt>
                            <dd>
                                {cargo.volume_cm3 != null
                                    ? `${cargo.volume_cm3.toLocaleString("es-AR")} ${t.summary.volumeUnit}`
                                    : t.summary.volumeNone}
                            </dd>
                        </div>
                        <div>
                            <dt>{t.summary.declaredValue}</dt>
                            <dd>
                                {arsFormatter.format(cargo.declared_value_cents / 100)}
                            </dd>
                        </div>
                        {cargo.distance_km != null && (
                            <div>
                                <dt>{t.summary.distance}</dt>
                                <dd>{formatDistance(parseFloat(cargo.distance_km))}</dd>
                            </div>
                        )}
                    </dl>
                    <CargoMapPreview
                        pickup={
                            cargo.pickup_lat && cargo.pickup_lng
                                ? {
                                    text: cargo.pickup_address,
                                    lat: parseFloat(cargo.pickup_lat),
                                    lng: parseFloat(cargo.pickup_lng),
                                }
                                : null
                        }
                        delivery={
                            cargo.delivery_lat && cargo.delivery_lng
                                ? {
                                    text: cargo.delivery_address,
                                    lat: parseFloat(cargo.delivery_lat),
                                    lng: parseFloat(cargo.delivery_lng),
                                }
                                : null
                        }
                        distanceKm={
                            cargo.distance_km != null
                                ? parseFloat(cargo.distance_km)
                                : undefined
                        }
                        showTitle={false}
                    />
                </section>

                <section
                    className="detailSection"
                    aria-labelledby="cargo-offers-title"
                >
                    <h2 id="cargo-offers-title" className="sectionSubtitle">
                        {t.sections.offers}
                    </h2>
                    {acceptedOffer && (
                        <div className="acceptedOfferPanel" role="status">
                            <h3 className="sectionSubtitle">
                                {t.offers.acceptedTitle}
                            </h3>
                            <p className="acceptedOfferCarrierName">
                                {acceptedOffer.carrier?.display_name ?? t.offers.carrierFallback}
                            </p>
                            <dl className="acceptedOfferMeta">
                                <div>
                                    <dt>{t.offers.acceptedAmountLabel}</dt>
                                    <dd>{arsFormatter.format(acceptedOffer.amount_cents / 100)}</dd>
                                </div>
                                {acceptedOffer.transport_window && (
                                    <div>
                                        <dt>{t.offers.acceptedWindowLabel}</dt>
                                        <dd>
                                            {t.offers.acceptedWindow(
                                                formatDate(acceptedOffer.transport_window.available_from),
                                                formatDate(acceptedOffer.transport_window.available_to),
                                            )}
                                        </dd>
                                    </div>
                                )}
                            </dl>
                        </div>
                    )}
                    {cargo.cargo_offers.filter((o) => o.status !== "accepted").length === 0 && !acceptedOffer ? (
                        <div className="emptyState">
                            <p className="sectionLead">{t.offers.empty}</p>
                            <p className="detailMuted">{t.offers.emptyHint}</p>
                            {cargo.editable && (
                                <Link
                                    to={`/shipper/cargos/${cargo.id}/matches`}
                                    className="button buttonPrimary"
                                >
                                    {t.searchCarriersCta}
                                </Link>
                            )}
                        </div>
                    ) : (
                        <ul className="offerList">
                            {cargo.cargo_offers
                                .filter((o) => o.status !== "accepted")
                                .map((o) => (
                                    <OfferRow key={o.id} offer={o} />
                                ))}
                        </ul>
                    )}
                </section>
            </div>

            <dialog
                ref={dialogRef}
                className="confirmDialog"
                onClose={() => setCancelOpen(false)}
                aria-labelledby="cancel-cargo-title"
            >
                <div className="confirmDialogBody">
                    <h2 id="cancel-cargo-title" className="confirmDialogTitle">
                        {t.cancelDialog.title}
                    </h2>
                    <p className="confirmDialogText">{t.cancelDialog.text}</p>
                    {cancelError && (
                        <Alert tone="error" role="alert">
                            {cancelError}
                        </Alert>
                    )}
                    <div className="confirmDialogField">
                        <label htmlFor="cancel-reason">
                            {t.cancelDialog.reasonLabel}
                        </label>
                        <textarea
                            id="cancel-reason"
                            className="confirmDialogTextarea"
                            rows={2}
                            value={cancelReason}
                            onChange={(e) => setCancelReason(e.target.value)}
                        />
                    </div>
                    <div className="confirmDialogActions">
                        <button
                            ref={dismissCancelRef}
                            className="button buttonGhost"
                            type="button"
                            onClick={() => setCancelOpen(false)}
                        >
                            {t.cancelDialog.cancel}
                        </button>
                        <button
                            className="button buttonDanger"
                            type="button"
                            onClick={handleCancel}
                            disabled={cancelling}
                        >
                            {cancelling
                                ? t.cancelDialog.cancelling
                                : t.cancelDialog.confirm}
                        </button>
                    </div>
                </div>
            </dialog>
        </main>
    );
}

function OfferRow({ offer }: { offer: CargoOffer }) {
    const window = offer.transport_window;
    const carrierName = offer.carrier?.display_name ?? cargosContent.match.carrierFallback;
    return (
        <li className="offerRow">
            <div className="offerContent">
                <div className="offerTopLine">
                    <span
                        className={`statusBadge ${
                            cargosContent.offerStatusBadgeClass[offer.status] ?? "pasado"
                        }`}
                    >
                        {cargosContent.offerStatusLabel[offer.status] ?? offer.status}
                    </span>
                    <span className="offerCarrier">{carrierName}</span>
                </div>
                {window && (
                    <span className="offerRoute">
                        {formatRoute(
                            { locality: window.origin_locality, admin_area: window.origin_admin_area },
                            window.destination_lat !== null
                                ? { locality: window.destination_locality, admin_area: window.destination_admin_area }
                                : null,
                            t.summary.openDestinationLabel,
                        )}
                    </span>
                )}
                <span className="offerMeta">{t.offers.expiresAt(formatDate(offer.expires_at))}</span>
            </div>
            <span className="offerAmount">
                {arsFormatter.format(offer.amount_cents / 100)}
            </span>
        </li>
    );
}
