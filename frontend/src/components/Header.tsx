import { lazy, Suspense } from "react";
import { Link } from "react-router-dom";
import { SessionWidget } from "./SessionWidget";
import { useCurrentUser } from "../auth/useCurrentUser";
const CarrierBadge = lazy(() => import("./CarrierBadge"));
// `offersAndShipmentsContent` used by secondary links; lazy badge imports its own copy.
import { offersAndShipmentsContent } from "../pages/carrier/offersAndShipmentsContent";

export function Header() {
    const { me } = useCurrentUser();

    const isCarrier = me?.roles.includes("carrier") ?? false;
    const headerText = offersAndShipmentsContent.header;

    return (
        <header className="appHeader" role="banner">
            <div className="appHeaderInner">
                <Link to="/" className="appHeaderBrand" aria-label="Truckr — Inicio">
                    Truckr®
                </Link>

                <nav aria-label="Account navigation">
                    <div className="appHeaderNavCluster">
                        {isCarrier && (
                            <>
                                <Link to="/carrier/cargo-offers" className="appHeaderLink appHeaderLinkPill">
                                    {headerText.inboxLink}
                                    <Suspense fallback={null}>
                                        <CarrierBadge />
                                    </Suspense>
                                </Link>
                            </>
                        )}
                        <SessionWidget />
                    </div>
                </nav>
            </div>
        </header>
    );
}
