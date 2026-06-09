import { Link } from "react-router-dom";
import type { CargoMatch } from "../../types/Cargo";
import { cargosContent } from "./cargosContent";
import { haversineKm } from "../../lib/geo";
import { formatRoute } from "../../lib/format-place";

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
    /** Cargo pickup point — used to compute the displayed Haversine distance. */
    pickup?: { lat: number; lng: number };
};

/**
 * One result in the cargo-scoped transport-window search
 * (`/shipper/cargos/:id/matches`) — a `TransportWindow` that can carry the
 * cargo. The card shows the carrier identity and price prominently; the shipper
 * browses and commits via an explicit "Enviar oferta" button (plan §9 D6).
 * "Ver perfil" links to the carrier's public profile without entering the offer
 * flow. When the caller supplies the cargo's `pickup` coords, the card shows
 * the Haversine distance from pickup to the window's origin.
 */
export default function MatchCard({ cargoId, match, pickup }: Props) {
    const hasDestination = match.destination_lat !== null;
    const route = formatRoute(
        { locality: match.origin_locality, admin_area: match.origin_admin_area },
        hasDestination
            ? { locality: match.destination_locality, admin_area: match.destination_admin_area }
            : null,
        cargosContent.list.openDestinationLabel,
    );
    const carrierName = match.carrier.display_name ?? t.carrierFallback;
    const distanceKm = pickup
        ? haversineKm(pickup, {
            lat: Number(match.origin_lat),
            lng: Number(match.origin_lng),
        })
        : null;

    const hasRating = match.carrier.reviews_count > 0;

    return (
        <li>
            <article className="matchCard">
                <div className="matchCardHeader">
                    <span className="matchCarrier">{carrierName}</span>
                    <span className="matchPriceTag">
                        {t.pricePerKm(match.price_per_km)}
                    </span>
                </div>
                <div className="matchCardBody">
                    <span className="matchRoute" title={route}>
                        {route}
                    </span>
                    {hasRating ? (
                        <span className="matchRating">
                            {t.rating(
                                match.carrier.rating_avg,
                                match.carrier.reviews_count,
                            )}
                        </span>
                    ) : (
                        <span className="matchMeta">{t.noRating}</span>
                    )}
                    <p className="matchMeta">
                        {t.vehicle(
                            match.vehicle.make,
                            match.vehicle.model,
                            match.vehicle.plate,
                        )}
                    </p>
                    <p className="matchMeta">
                        {t.capacity(match.vehicle.max_load_kg)}
                    </p>
                    <p className="matchMeta">
                        {t.availability(
                            formatDate(match.available_from),
                            formatDate(match.available_to),
                        )}
                    </p>
                    {distanceKm !== null && (
                        <p className="matchMeta matchDistance">
                            {t.distanceKm(distanceKm)}
                        </p>
                    )}
                </div>
                <div className="cardActions matchCardActions">
                    <Link
                        className="button buttonGhost"
                        to={`/carriers/${match.carrier.id}`}
                        state={{ backToMatches: `/shipper/cargos/${cargoId}/matches` }}
                    >
                        {t.viewCarrierDetail}
                    </Link>
                    <Link
                        className="button buttonPrimary"
                        to={`/shipper/cargos/${cargoId}/offers/new?window=${match.id}`}
                        state={{ window: match }}
                        aria-label={t.offerCtaAria(route)}
                    >
                        {t.offerCta}
                    </Link>
                </div>
            </article>
        </li>
    );
}
