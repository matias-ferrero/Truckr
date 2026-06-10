/* Inline line-icons for the Sidebar nav items. Matches the project's existing
   SVG idiom (24×24 viewBox, fill:none, stroke:currentColor, round caps/joins)
   used across DashboardPage / ShipmentActions — no icon-library dependency.
   Icons are decorative: aria-hidden, the link's text carries the a11y name. */
import type { JSX } from "react";

export type SidebarIconName =
    | "truck"
    | "calendar"
    | "inbox"
    | "package"
    | "wallet"
    | "home"
    | "boxes";

const PATHS: Record<SidebarIconName, JSX.Element> = {
    // Vehículos
    truck: (
        <>
            <path d="M14 18V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v11a1 1 0 0 0 1 1h2" />
            <path d="M15 18H9" />
            <path d="M19 18h2a1 1 0 0 0 1-1v-3.65a1 1 0 0 0-.22-.62l-3.48-4.35A1 1 0 0 0 17.52 8H14" />
            <circle cx="7" cy="18" r="2" />
            <circle cx="17" cy="18" r="2" />
        </>
    ),
    // Disponibilidad
    calendar: (
        <>
            <path d="M8 2v4" />
            <path d="M16 2v4" />
            <rect width="18" height="18" x="3" y="4" rx="2" />
            <path d="M3 10h18" />
        </>
    ),
    // Ofertas
    inbox: (
        <>
            <polyline points="22 12 16 12 14 15 10 15 8 12 2 12" />
            <path d="M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z" />
        </>
    ),
    // Mis Envíos
    package: (
        <>
            <path d="m7.5 4.27 9 5.15" />
            <path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z" />
            <path d="m3.3 7 8.7 5 8.7-5" />
            <path d="M12 22V12" />
        </>
    ),
    // Mis Pagos
    wallet: (
        <>
            <path d="M19 7V4a1 1 0 0 0-1-1H5a2 2 0 0 0 0 4h15a1 1 0 0 1 1 1v4h-3a2 2 0 0 0 0 4h3a1 1 0 0 1-1 1H5a2 2 0 0 1-2-2V5" />
            <path d="M3 5a2 2 0 0 1 2-2" />
        </>
    ),
    // Inicio
    home: (
        <>
            <path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
            <polyline points="9 22 9 12 15 12 15 22" />
        </>
    ),
    // Mis Cargas
    boxes: (
        <>
            <path d="M7.97 4.42A2 2 0 0 0 7 6.13v4.37l5 3 5-3V6.13a2 2 0 0 0-.97-1.71l-3-1.8a2 2 0 0 0-2.06 0z" />
            <path d="m12 8 4.74-2.85" />
            <path d="M12 13.5V8" />
            <path d="M2.97 12.92A2 2 0 0 0 2 14.63v3.24a2 2 0 0 0 .97 1.71l3 1.8a2 2 0 0 0 2.06 0L12 19v-5.5l-5-3z" />
            <path d="m7 16.5 5-3" />
            <path d="M7 16.5v5.17" />
            <path d="M12 13.5 17 10.5l4.03 2.42a2 2 0 0 1 .97 1.71v3.24a2 2 0 0 1-.97 1.71l-3 1.8a2 2 0 0 1-2.06 0L12 19z" />
            <path d="m17 16.5-5-3" />
            <path d="M17 16.5v5.17" />
        </>
    ),
};

export function SidebarIcon({ name }: { name: SidebarIconName }) {
    return (
        <svg
            className="appSidebarIcon"
            viewBox="0 0 24 24"
            width="20"
            height="20"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.75"
            strokeLinecap="round"
            strokeLinejoin="round"
            aria-hidden="true"
        >
            {PATHS[name]}
        </svg>
    );
}
