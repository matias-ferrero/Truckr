import { Link } from "react-router-dom";
import { SessionWidget } from "./SessionWidget";

export function Header() {
    return (
        <header className="appHeader" role="banner">
            <div className="appHeaderInner">
                <Link to="/" className="appHeaderBrand" aria-label="Truckr — Inicio">
                    Truckr®
                </Link>

                <nav aria-label="Cuenta">
                    <SessionWidget />
                </nav>
            </div>
        </header>
    );
}
