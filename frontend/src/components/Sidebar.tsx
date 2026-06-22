import { lazy, Suspense } from "react";
import { NavLink } from "react-router-dom";
import { useCurrentUser } from "../auth/useCurrentUser";
import { sidebarContent as t } from "./sidebarContent";
import { SidebarIcon, type SidebarIconName } from "./sidebarIcons";
import "../styles/sidebar.css";

const CarrierBadge = lazy(() => import("./CarrierBadge"));

type SidebarItem = {
    to: string;
    label: string;
    icon: SidebarIconName;
    /** Render the live pending-cargo-offers count after the label. */
    badge?: boolean;
};

function linkClass({ isActive }: { isActive: boolean }) {
    return isActive ? "appSidebarLink appSidebarLink--active" : "appSidebarLink";
}

function SidebarGroup(
    { id, heading, items }: { id: string; heading: string; items: SidebarItem[] },
) {
    const headingId = `appSidebarHeading-${id}`;
    return (
        <div className="appSidebarGroup">
            <p className="appSidebarHeading" id={headingId}>{heading}</p>
            {/* aria-labelledby names the list so dual-role SR users can tell
                the Transportista list from the Expedidor list. */}
            <ul className="appSidebarList" aria-labelledby={headingId}>
                {items.map((item) => (
                    <li key={item.to}>
                        {/* `end` omitted so detail routes (e.g. /carrier/shipments/:id)
                            keep their section link active. */}
                        <NavLink to={item.to} className={linkClass}>
                            <SidebarIcon name={item.icon} />
                            <span className="appSidebarLabel">{item.label}</span>
                            {item.badge && (
                                <Suspense fallback={null}>
                                    <CarrierBadge className="appSidebarBadge" />
                                </Suspense>
                            )}
                        </NavLink>
                    </li>
                ))}
            </ul>
        </div>
    );
}

/**
 * Persistent role-aware navigation rail. Rendered inside the authenticated
 * app shells (carrier, shipper, dashboard) so it appears on every page of the
 * logged-in app. Shows the Carrier group, the Shipper group, or both for
 * dual-role users; renders nothing for anonymous visitors.
 */
export function Sidebar() {
    const { me } = useCurrentUser();
    const isCarrier = me?.roles.includes("carrier") ?? false;
    const isShipper = me?.roles.includes("shipper") ?? false;

    if (!isCarrier && !isShipper) return null;

    const carrierItems: SidebarItem[] = [
        { to: "/carrier/dashboard", label: t.carrier.items.dashboard, icon: "home" },
        { to: "/carrier/vehicles", label: t.carrier.items.vehicles, icon: "truck" },
        { to: "/carrier/availability", label: t.carrier.items.availability, icon: "calendar" },
        { to: "/carrier/cargo-offers", label: t.carrier.items.offers, icon: "inbox", badge: true },
        { to: "/carrier/shipments", label: t.carrier.items.shipments, icon: "package" },
        { to: "/carrier/payouts", label: t.carrier.items.payouts, icon: "wallet" },
    ];
    const shipperItems: SidebarItem[] = [
        { to: "/shipper/dashboard", label: t.shipper.items.dashboard, icon: "home" },
        { to: "/shipper/cargos", label: t.shipper.items.cargos, icon: "boxes" },
        { to: "/shipper/shipments", label: t.shipper.items.shipments, icon: "package" },
    ];

    return (
        <nav className="appSidebar" aria-label={t.label}>
            {isCarrier && <SidebarGroup id="carrier" heading={t.carrier.heading} items={carrierItems} />}
            {isShipper && <SidebarGroup id="shipper" heading={t.shipper.heading} items={shipperItems} />}
        </nav>
    );
}

export default Sidebar;
