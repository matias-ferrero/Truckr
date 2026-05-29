import { useEffect, useState } from "react";
import { Link, useLocation, useNavigate, useParams, useSearchParams } from "react-router-dom";
import { createCargoOffer } from "../../api/cargoOffers";
import { getCargo, getMatches } from "../../features/cargo/api";
import type { Cargo, CargoMatch } from "../../types/Cargo";
import { offerContent } from "./offerContent";
import { formatRoute } from "../../lib/format-place";
import { FormField } from "../../components/ui/form-field";
import { Input } from "../../components/ui/input";
import { Button } from "../../components/ui/button";
import { Alert } from "../../components/ui/alert";

const t = offerContent;

const arsFormatter = new Intl.NumberFormat("es-AR", {
    style: "currency",
    currency: "ARS",
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

/** Router state set by MatchCard when launching the offer flow. */
type NavState = { window?: CargoMatch };

type LoadState =
    | { status: "loading" }
    | { status: "ready"; cargo: Cargo; window: CargoMatch }
    | { status: "error" };

/**
 * Cargo-scoped offer confirm step (US7 / REQ-FE-00015 remediation, plan §4.10).
 *
 * Route: `/shipper/cargos/:id/offers/new?window=:windowId`. The offer bids an
 * already-published `Cargo` against a chosen `TransportWindow`. The window is
 * passed via router state from the match list, with a `getMatches` refetch
 * fallback for deep links / reloads. The old 3-step wizard (addresses, cargo
 * fields, date) is gone — that data lives on the published Cargo.
 */
export default function CreateOfferPage() {
    const { id } = useParams<{ id: string }>();
    const cargoId = Number(id);
    const [searchParams] = useSearchParams();
    const windowId = Number(searchParams.get("window"));
    const location = useLocation();
    const navigate = useNavigate();

    const navWindow = (location.state as NavState | null)?.window;

    const [state, setState] = useState<LoadState>({ status: "loading" });
    const [estimatedKm, setEstimatedKm] = useState("");
    const [kmTouched, setKmTouched] = useState(false);
    const [submitError, setSubmitError] = useState<string | null>(null);
    const [submitting, setSubmitting] = useState(false);

    useEffect(() => {
        let cancelled = false;
        (async () => {
            try {
                const cargo = await getCargo(cargoId);
                // Prefer the window from router state; fall back to the match
                // list when the page is reached via deep link / reload.
                let window = navWindow ?? null;
                if (!window || window.id !== windowId) {
                    const matches = await getMatches(cargoId);
                    window = matches.items.find((m) => m.id === windowId) ?? null;
                }
                if (cancelled) return;
                if (!window) {
                    setState({ status: "error" });
                    return;
                }
                setState({ status: "ready", cargo, window });
            } catch {
                if (!cancelled) setState({ status: "error" });
            }
        })();
        return () => {
            cancelled = true;
        };
        // navWindow is read once on mount; windowId/cargoId drive the fetch.
    }, [cargoId, windowId]);

    const parsedKm = parseFloat(estimatedKm);
    const kmValid = parsedKm > 0;

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        setKmTouched(true);
        if (!kmValid || state.status !== "ready") return;
        setSubmitting(true);
        setSubmitError(null);
        try {
            await createCargoOffer(cargoId, {
                transport_window_id: state.window.id,
                estimated_km: estimatedKm,
            });
            navigate(`/shipper/cargos/${cargoId}`);
        } catch {
            // The backend rejects e.g. a contended window (window-lock, §2.7)
            // or an inactive window — surface a single recoverable message.
            setSubmitError(t.errors.saveError);
        } finally {
            setSubmitting(false);
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
                    <Alert tone="error" aria-live="assertive">
                        {t.loadError}
                    </Alert>
                    <Link to={`/shipper/cargos/${cargoId}`} className="backLink">
                        {t.backToCargo}
                    </Link>
                </div>
            </main>
        );
    }

    const { cargo, window } = state;
    const pricePerKm = parseFloat(window.price_per_km);
    const estimatedCost = kmValid && pricePerKm > 0
        ? parsedKm * pricePerKm
        : null;
    const carrierName = window.carrier.display_name ??
        t.windowSection.carrierFallback;

    return (
        <main className="page" id="main">
            <div className="container">
                <Link to={`/shipper/cargos/${cargoId}`} className="backLink">
                    {t.backToCargo}
                </Link>
                <header className="formHeader">
                    <h1 className="sectionTitle">{t.title}</h1>
                    <p className="sectionLead">{t.lead}</p>
                </header>

                <section
                    className="offerSummaryCard"
                    aria-labelledby="offer-cargo-title"
                >
                    <h2 id="offer-cargo-title" className="sectionSubtitle">
                        {t.cargoSection.heading}
                    </h2>
                    <p className="offerSummaryRoute">
                        {formatRoute(
                            { locality: cargo.pickup_locality, admin_area: cargo.pickup_admin_area },
                            { locality: cargo.delivery_locality, admin_area: cargo.delivery_admin_area },
                            t.openDestinationLabel,
                        )}
                    </p>
                    <p className="cargoCardDescription">
                        {cargo.cargo_description}
                    </p>
                    <dl className="detailGrid">
                        <div>
                            <dt>{t.cargoSection.pickup}</dt>
                            <dd>{cargo.pickup_address}</dd>
                        </div>
                        <div>
                            <dt>{t.cargoSection.delivery}</dt>
                            <dd>{cargo.delivery_address}</dd>
                        </div>
                        <div>
                            <dt>{t.cargoSection.pickupWindow}</dt>
                            <dd>
                                {formatDateTime(cargo.pickup_window_start)}
                                {" – "}
                                {formatDateTime(cargo.pickup_window_end)}
                            </dd>
                        </div>
                        <div>
                            <dt>{t.cargoSection.weight}</dt>
                            <dd>
                                {cargo.weight_kg} {t.cargoSection.weightUnit}
                            </dd>
                        </div>
                    </dl>
                </section>

                <section
                    className="offerSummaryCard"
                    aria-labelledby="offer-window-title"
                >
                    <h2 id="offer-window-title" className="sectionSubtitle">
                        {t.windowSection.heading}
                    </h2>
                    <p className="offerSummaryRoute">
                        {formatRoute(
                            { locality: window.origin_locality, admin_area: window.origin_admin_area },
                            window.destination_lat !== null
                                ? { locality: window.destination_locality, admin_area: window.destination_admin_area }
                                : null,
                            t.openDestinationLabel,
                        )}
                    </p>
                    <p className="offerSummaryMeta">
                        {t.windowSection.carrier(carrierName)}
                    </p>
                    <p className="offerSummaryMeta">
                        {t.windowSection.vehicle(
                            window.vehicle.make,
                            window.vehicle.model,
                            window.vehicle.plate,
                        )}
                    </p>
                    <p className="offerSummaryMeta">
                        {t.windowSection.availability(
                            formatDate(window.available_from),
                            formatDate(window.available_to),
                        )}
                        {" · "}
                        {t.windowSection.rate(window.price_per_km)}
                    </p>
                </section>

                <form className="offerForm" onSubmit={handleSubmit} noValidate>
                    {submitError && (
                        <Alert tone="error" aria-live="assertive">
                            {submitError}
                        </Alert>
                    )}
                    <FormField
                        id="estimated_km"
                        label={t.estimatedKm}
                        error={
                            kmTouched && !kmValid ? t.estimatedKmError : undefined
                        }
                        required
                    >
                        <Input
                            id="estimated_km"
                            type="number"
                            min="1"
                            step="1"
                            value={estimatedKm}
                            onChange={(e) => setEstimatedKm(e.target.value)}
                            onBlur={() => setKmTouched(true)}
                        />
                    </FormField>
                    <div
                        className="costEstimate"
                        aria-live="polite"
                        data-testid="cost-estimate"
                    >
                        <span>{t.estimatedCost}: </span>
                        <strong>
                            {estimatedCost != null
                                ? arsFormatter.format(estimatedCost)
                                : t.noEstimate}
                        </strong>
                    </div>
                    <div className="offerFormActions">
                        <Button type="submit" disabled={submitting}>
                            {submitting ? t.submitting : t.submit}
                        </Button>
                        <Button
                            type="button"
                            variant="ghost"
                            onClick={() =>
                                navigate(`/shipper/cargos/${cargoId}`)}
                        >
                            {t.cancel}
                        </Button>
                    </div>
                </form>
            </div>
        </main>
    );
}
