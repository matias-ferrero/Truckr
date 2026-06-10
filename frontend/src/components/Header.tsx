import { lazy, Suspense } from "react";
import { Link } from "react-router-dom";
import { SessionWidget } from "./SessionWidget";
import { useCurrentUser } from "../auth/useCurrentUser";
const NotificationsBadge = lazy(() => import("./notifications/NotificationsBadge"));

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
                        {/* Carrier section links ("Bandeja", "Mis Pagos") now live in
                            the persistent Sidebar; the inbox badge moved with them. */}
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
