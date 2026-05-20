import { useCallback, useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { getCargo, getMatches } from "./api";
import type { Cargo, CargoMatch } from "../../types/Cargo";
import { cargosContent } from "./cargosContent";
import MatchCard from "./MatchCard";
import { Alert } from "../../components/ui/alert";

const t = cargosContent.matchesScreen;

function formatDate(iso: string): string {
    return new Date(iso).toLocaleDateString("es-AR", {
        day: "2-digit",
        month: "2-digit",
        year: "2-digit",
    });
}

type CargoState =
    | { status: "loading" }
    | { status: "ready"; cargo: Cargo }
    | { status: "error"; message: string };

type MatchesState =
    | { status: "idle" }
    | { status: "loading" }
    | { status: "ready"; items: CargoMatch[] }
    | { status: "error" };

/**
 * `/shipper/cargos/:id/matches` — the cargo-scoped transport-window search
 * screen (plan §9 D2). Pins the selected cargo on top and lists the
 * `GET /api/cargos/:id/matches` results; each result links straight into the
 * cargo-scoped offer flow. The single funnel:
 * dashboard → cargo → matches → offer.
 */
export default function CargoMatches() {
    const params = useParams<{ id: string }>();
    const cargoId = Number(params.id);

    const [state, setState] = useState<CargoState>({ status: "loading" });
    const [matches, setMatches] = useState<MatchesState>({ status: "idle" });

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

    // Matches are only meaningful while the cargo is still open (plan §9 D3):
    // a non-open cargo can't take new offers, so skip the request entirely.
    useEffect(() => {
        if (state.status !== "ready" || state.cargo.status !== "open") {
            setMatches({ status: "idle" });
            return;
        }
        let cancelled = false;
        setMatches({ status: "loading" });
        getMatches(cargoId)
            .then((res) => {
                if (!cancelled) setMatches({ status: "ready", items: res.items });
            })
            .catch(() => {
                if (!cancelled) setMatches({ status: "error" });
            });
        return () => {
            cancelled = true;
        };
    }, [state, cargoId]);

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
    const route = cargosContent.list.route(cargo.pickup_zone, cargo.delivery_zone);

    return (
        <main className="page" id="main">
            <div className="container">
                <Link to={`/shipper/cargos/${cargo.id}`} className="backLink">
                    {t.backToCargo}
                </Link>

                <header className="listHeader">
                    <div>
                        <h1 className="sectionTitle">{t.title}</h1>
                        <p className="sectionLead">{t.lead}</p>
                    </div>
                </header>

                <div className="selectedCargoCard">
                    <span className="selectedCargoEyebrow">
                        {t.selectedCargoLabel}
                    </span>
                    <div className="cargoCardHeader">
                        <span className="cargoRoute" title={route}>
                            {route}
                        </span>
                        <span
                            className={`statusBadge ${
                                cargosContent.statusBadgeClass[cargo.status] ??
                                "pendiente"
                            }`}
                        >
                            {cargosContent.statusLabel[cargo.status] ??
                                cargo.status}
                        </span>
                    </div>
                    <p className="cargoCardDescription">
                        {cargo.cargo_description}
                    </p>
                    <p className="cargoCardMeta">
                        {cargosContent.list.pickupWindow(
                            formatDate(cargo.pickup_window_start),
                            formatDate(cargo.pickup_window_end),
                        )}
                    </p>
                    <Link
                        to={`/shipper/cargos/${cargo.id}`}
                        className="button buttonGhost"
                    >
                        {t.viewCargoDetail}
                    </Link>
                </div>

                {cargo.status !== "open" ? (
                    <div className="emptyState">
                        <h2 className="emptyStateTitle">{t.notOpenTitle}</h2>
                        <p className="sectionLead">{t.notOpenLead}</p>
                        <Link
                            to={`/shipper/cargos/${cargo.id}`}
                            className="button buttonPrimary"
                        >
                            {t.viewCargoDetail}
                        </Link>
                    </div>
                ) : (
                    <section
                        className="detailSection"
                        aria-labelledby="cargo-matches-title"
                    >
                        <h2
                            id="cargo-matches-title"
                            className="sectionSubtitle"
                        >
                            {t.listLabel}
                        </h2>
                        {matches.status === "loading" && (
                            <p
                                className="sectionLead"
                                role="status"
                                aria-busy="true"
                            >
                                {t.matchesLoading}
                            </p>
                        )}
                        {matches.status === "error" && (
                            <Alert tone="error" role="alert">
                                {t.matchesError}
                            </Alert>
                        )}
                        {matches.status === "ready" &&
                            matches.items.length === 0 && (
                                <p className="detailMuted">{t.matchesEmpty}</p>
                            )}
                        {matches.status === "ready" &&
                            matches.items.length > 0 && (
                                <ul className="matchList">
                                    {matches.items.map((m) => (
                                        <MatchCard
                                            key={m.id}
                                            cargoId={cargo.id}
                                            match={m}
                                        />
                                    ))}
                                </ul>
                            )}
                    </section>
                )}
            </div>
        </main>
    );
}
