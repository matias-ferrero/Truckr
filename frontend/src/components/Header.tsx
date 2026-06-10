import { lazy, Suspense } from "react";
import { Link } from "react-router-dom";
import { SessionWidget } from "./SessionWidget";
import { useCurrentUser } from "../auth/useCurrentUser";
const NotificationsBadge = lazy(() => import("./notifications/NotificationsBadge"));

// Carrier section links ("Bandeja", "Mis Pagos", "Mis Viajes") and the
// pending-offers badge live in the persistent Sidebar; the cargo-offers pill
// and payouts shortcut also surface in the Carrier-Dashboard-v2 board. The
// header keeps only brand + notifications + session.
export function Header() {
    const { me } = useCurrentUser();

    const isAuthenticated = me != null;

    return (
        <header className="appHeader" role="banner">
            <div className="appHeaderInner">
                <Link to="/" className="appHeaderBrand" aria-label="Truckr — Inicio">
                    Truckr®
                </Link>

                <nav aria-label="Account navigation">
                    <div className="appHeaderNavCluster">
                        {isAuthenticated && (
                            <Suspense fallback={null}>
                                <NotificationsBadge />
                            </Suspense>
                        )}
                        <SessionWidget />
                    </div>
                </nav>
            </div>
        </header>
    );
}
