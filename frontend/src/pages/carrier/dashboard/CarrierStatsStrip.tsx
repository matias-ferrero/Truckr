import { Link } from "react-router-dom";
import type { CarrierSupply } from "./buildCarrierDashboardModel";
import { carrierDashboardContent as t } from "./carrierDashboardContent";

/** Quiet, glanceable supply posture: fleet size, open windows, own rating.
 *  Status — never a to-do. Stroke icons are decorative; text carries meaning. */
function StatIcon({ kind }: { kind: "truck" | "window" | "star" }) {
    const paths = {
        truck: (
            <>
                <path d="M2 7h12v9H2z" />
                <path d="M14 10h4l3 3.5V16h-7" />
                <circle cx="6" cy="18" r="1.8" />
                <circle cx="17.5" cy="18" r="1.8" />
            </>
        ),
        window: (
            <>
                <rect x="3" y="5" width="18" height="16" rx="2" />
                <path d="M3 9h18" />
                <path d="M8 3v4M16 3v4" />
            </>
        ),
        star: (
            <path d="m12 3.5 2.6 5.4 5.9.8-4.3 4.1 1 5.8-5.2-2.8-5.2 2.8 1-5.8L3.5 9.7l5.9-.8L12 3.5z" />
        ),
    };
    return (
        <svg
            viewBox="0 0 24 24"
            width="18"
            height="18"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.8"
            strokeLinecap="round"
            strokeLinejoin="round"
            aria-hidden="true"
        >
            {paths[kind]}
        </svg>
    );
}

export function CarrierStatsStrip({ stats }: { stats: CarrierSupply }) {
    return (
        <ul className="dashStats" aria-label={t.stats.regionLabel}>
            <li className="dashStats__item">
                <Link to={t.stats.vehiclesHref} className="dashStats__link">
                    <StatIcon kind="truck" />
                    {t.stats.vehicles(stats.vehiclesCount)}
                </Link>
            </li>
            <li className="dashStats__item">
                <Link to={t.stats.windowsHref} className="dashStats__link">
                    <StatIcon kind="window" />
                    {t.stats.openWindows(stats.openWindowsCount)}
                </Link>
            </li>
            <li className="dashStats__item dashStats__item--static">
                <StatIcon kind="star" />
                {stats.ratingAvg ? t.stats.rating(stats.ratingAvg) : t.stats.ratingEmpty}
            </li>
        </ul>
    );
}
