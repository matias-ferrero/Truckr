import { useCallback, useEffect, useMemo, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { getCargo, getMatches } from "./api";
import type { Cargo, CargoMatch } from "../../types/Cargo";
import {
    buildMatchesModel,
    DEFAULT_SORT,
    EMPTY_FILTERS,
    type MatchFilters,
    type MatchSort,
} from "./buildMatchesModel";
import { cargoMatchesContent } from "./cargoMatchesContent";
import CargoContextBar from "./CargoContextBar";
import RecommendedStrip from "./RecommendedStrip";
import MatchesControls from "./MatchesControls";
import MatchesPagination from "./MatchesPagination";
import MatchCard from "./MatchCard";
import { Alert } from "../../components/ui/alert";
import "../../styles/cargoMatches.css";

const t = cargoMatchesContent;

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
 * `/shipper/cargos/:id/matches` — the Cargo Matches v2 decision screen
 * (docs/features/cargo-matches-v2.prd.md). Fetches the *full* compatible
 * set once; a pure `buildMatchesModel` derives the Recomendados picks and
 * the sortable / filterable / client-paginated grid. The single funnel:
 * dashboard → cargo → matches → offer.
 */
export default function CargoMatches() {
    const params = useParams<{ id: string }>();
    const cargoId = Number(params.id);

    const [state, setState] = useState<CargoState>({ status: "loading" });
    const [matches, setMatches] = useState<MatchesState>({ status: "idle" });
    const [sort, setSort] = useState<MatchSort>(DEFAULT_SORT);
    const [filters, setFilters] = useState<MatchFilters>(EMPTY_FILTERS);
    const [page, setPage] = useState(1);

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

    // Matches are only meaningful while the cargo is still open: a non-open
    // cargo can't take new offers, so skip the request entirely.
    useEffect(() => {
        if (state.status !== "ready" || state.cargo.status !== "open") {
            setMatches({ status: "idle" });
            return;
        }
        let cancelled = false;
        setMatches({ status: "loading" });
        getMatches(cargoId)
            .then((items) => {
                if (!cancelled) setMatches({ status: "ready", items });
            })
            .catch(() => {
                if (!cancelled) setMatches({ status: "error" });
            });
        return () => {
            cancelled = true;
        };
    }, [state, cargoId]);

    const cargo = state.status === "ready" ? state.cargo : null;

    const model = useMemo(() => {
        if (matches.status !== "ready" || cargo === null) return null;
        return buildMatchesModel(matches.items, {
            distanceKm: cargo.distance_km !== null
                ? Number(cargo.distance_km)
                : null,
            pickup: {
                lat: Number(cargo.pickup_lat),
                lng: Number(cargo.pickup_lng),
            },
        }, { sort, filters, page });
    }, [matches, cargo, sort, filters, page]);

    const changeSort = (next: MatchSort) => {
        setSort(next);
        setPage(1);
    };
    const changeFilters = (next: MatchFilters) => {
        setFilters(next);
        setPage(1);
    };

    if (state.status === "loading") {
        return (
            <main className="page matchesPage" id="main">
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
            <main className="page matchesPage" id="main">
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

    const readyCargo = state.cargo;

    return (
        <main className="page matchesPage" id="main">
            <div className="container">
                <Link
                    to={`/shipper/cargos/${readyCargo.id}`}
                    className="backLink"
                >
                    {t.backToCargo}
                </Link>

                <header className="listHeader">
                    <div>
                        <h1 className="sectionTitle">{t.title}</h1>
                        <p className="sectionLead">{t.lead}</p>
                    </div>
                </header>

                <CargoContextBar cargo={readyCargo} />

                {readyCargo.status !== "open"
                    ? (
                        <div className="emptyState">
                            <h2 className="emptyStateTitle">
                                {t.notOpen.title}
                            </h2>
                            <p className="sectionLead">{t.notOpen.lead}</p>
                            <Link
                                to={`/shipper/cargos/${readyCargo.id}`}
                                className="button buttonPrimary"
                            >
                                {t.notOpen.cta}
                            </Link>
                        </div>
                    )
                    : (
                        <>
                            {matches.status === "loading" && (
                                <p
                                    className="sectionLead"
                                    role="status"
                                    aria-busy="true"
                                >
                                    {t.states.matchesLoading}
                                </p>
                            )}
                            {matches.status === "error" && (
                                <Alert tone="error" role="alert">
                                    {t.states.matchesError}
                                </Alert>
                            )}
                            {model !== null && model.totalCount === 0 && (
                                <div className="emptyState">
                                    <h2 className="emptyStateTitle">
                                        {t.states.matchesEmptyTitle}
                                    </h2>
                                    <p className="sectionLead">
                                        {t.states.matchesEmptyHint}
                                    </p>
                                    <Link
                                        to={`/shipper/cargos/${readyCargo.id}`}
                                        className="button buttonPrimary"
                                    >
                                        {t.states.matchesEmptyCta}
                                    </Link>
                                </div>
                            )}
                            {model !== null && model.totalCount > 0 && (
                                <>
                                    <RecommendedStrip
                                        cargoId={readyCargo.id}
                                        picks={model.picks}
                                    />
                                    <section
                                        className="matchesSection"
                                        aria-labelledby="cargo-matches-title"
                                    >
                                        <h2
                                            id="cargo-matches-title"
                                            className="sectionSubtitle"
                                        >
                                            {t.controls.heading}
                                        </h2>
                                        <MatchesControls
                                            sort={sort}
                                            filters={filters}
                                            shownCount={model.filteredCount}
                                            totalCount={model.totalCount}
                                            onSortChange={changeSort}
                                            onFiltersChange={changeFilters}
                                        />
                                        {model.filteredCount === 0
                                            ? (
                                                <p className="detailMuted matchesNoResults">
                                                    {t.controls.noFilterResults}
                                                </p>
                                            )
                                            : (
                                                <ul className="matchGrid">
                                                    {model.rows.map((row) => (
                                                        <MatchCard
                                                            key={row.match.id}
                                                            cargoId={readyCargo
                                                                .id}
                                                            row={row}
                                                        />
                                                    ))}
                                                </ul>
                                            )}
                                        <MatchesPagination
                                            page={model.page}
                                            pageCount={model.pageCount}
                                            onPageChange={setPage}
                                        />
                                    </section>
                                </>
                            )}
                        </>
                    )}
            </div>
        </main>
    );
}
