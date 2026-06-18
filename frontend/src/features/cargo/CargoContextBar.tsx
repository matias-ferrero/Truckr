import { Link } from "react-router-dom";
import type { Cargo } from "../../types/Cargo";
import { cargoMatchesContent } from "./cargoMatchesContent";
import { cargosContent } from "./cargosContent";
import { formatRoute } from "../../lib/format-place";
import { formatKg, formatShortDate } from "./matchesFormat";

const t = cargoMatchesContent.contextBar;

type Props = {
    cargo: Cargo;
};

/**
 * Compact, sticky summary of the cargo being matched — keeps the referent
 * ("what am I comparing carriers *for*?") visible while the Shipper sorts
 * and scrolls the grid below.
 */
export default function CargoContextBar({ cargo }: Props) {
    const route = formatRoute(
        { locality: cargo.pickup_locality, admin_area: cargo.pickup_admin_area },
        { locality: cargo.delivery_locality, admin_area: cargo.delivery_admin_area },
        cargosContent.list.openDestinationLabel,
    );

    return (
        <div className="cargoContextBar">
            <span className="cargoContextEyebrow">{t.eyebrow}</span>
            <span className="cargoContextRoute" title={route}>{route}</span>
            <span className="cargoContextMeta">
                {formatKg(cargo.weight_kg)}
                {" · "}
                {t.pickupWindow(
                    formatShortDate(cargo.pickup_window_start),
                    formatShortDate(cargo.pickup_window_end),
                )}
            </span>
            <Link
                to={`/shipper/cargos/${cargo.id}`}
                className="cargoContextLink"
            >
                {t.viewDetail}
            </Link>
        </div>
    );
}
