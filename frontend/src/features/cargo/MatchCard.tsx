import { Link } from "react-router-dom";
import type { CargoMatch } from "../../types/Cargo";
import { cargosContent } from "./cargosContent";

const t = cargosContent.match;

function formatDate(iso: string): string {
    return new Date(iso).toLocaleDateString("es-AR", {
        day: "2-digit",
        month: "2-digit",
        year: "2-digit",
    });
}

type Props = {
    cargoId: number;
    match: CargoMatch;
};

/**
 * One result in the cargo-scoped transport-window search
 * (`/shipper/cargos/:id/matches`) — a `TransportWindow` that can carry the
 * cargo. The whole card is a single `<Link>` straight into the cargo-scoped
 * offer flow (plan §9 D6): one action per result, no separate button. No
 * distance is shown — Haversine is deferred to the GMaps follow-up.
 */
export default function MatchCard({ cargoId, match }: Props) {
    const route = cargosContent.list.route(
        match.origin_zone,
        match.destination_zone,
    );
    const carrierName = match.carrier.display_name ?? t.carrierFallback;

    return (
        <li>
            <Link
                className="matchCard"
                to={`/shipper/cargos/${cargoId}/offers/new?window=${match.id}`}
                state={{ window: match }}
                aria-label={t.offerCtaAria(route)}
            >
                <div className="matchCardHeader">
                    <span className="matchRoute" title={route}>
                        {route}
                    </span>
                    <span className="matchRating">
                        {t.rating(match.carrier.rating_avg)}
                    </span>
                </div>
                <p className="matchCarrier">{t.carrier(carrierName)}</p>
                <p className="matchMeta">
                    {t.vehicle(
                        match.vehicle.make,
                        match.vehicle.model,
                        match.vehicle.plate,
                    )}
                </p>
                <p className="matchMeta">{t.capacity(match.vehicle.max_load_kg)}</p>
                <p className="matchMeta">
                    {t.availability(
                        formatDate(match.available_from),
                        formatDate(match.available_to),
                    )}
                    {" · "}
                    {t.pricePerKm(match.price_per_km)}
                </p>
            </Link>
        </li>
    );
}
