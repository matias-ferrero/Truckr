import { Link, useLocation, useNavigate } from "react-router-dom";
import { useCurrentUser } from "../auth/useCurrentUser";
import { Button } from "./ui/button";

/**
 * Auth-state chip used by both the dashboard `Header` and the landing
 * topbar. The user's name acts as the single profile entry point:
 * carriers go to their public profile (which links to /profile for
 * edit), shippers go directly to /profile (no public show page exists).
 * Anonymous users see login / register links instead.
 */
export function SessionWidget() {
    const { me, loading, logout } = useCurrentUser();
    const navigate = useNavigate();
    const location = useLocation();

    if (loading) return <span className="appHeaderEmail" aria-hidden="true">…</span>;

    const onLogout = async () => {
        try {
            await logout();
        } finally {
            navigate("/login");
        }
    };

    if (me) {
        const displayName = me.full_name || me.email;
        const isCarrier = me.roles.includes("carrier");
        const profileHref = isCarrier ? "/carriers/me" : "/profile";
        const profileLabel = isCarrier
            ? `Perfil público de ${displayName}`
            : `Mi perfil — ${displayName}`;
        return (
            <div className="appHeaderActions">
                <Link
                    to={profileHref}
                    className="appHeaderProfile"
                    aria-label={profileLabel}
                >
                    {displayName}
                </Link>
                <Button variant="ghost" size="sm" onClick={onLogout}>
                    Salir
                </Button>
            </div>
        );
    }

    return (
        <div className="appHeaderActions">
            {location.pathname !== "/login" ? (
                <Link to="/login" className="appHeaderLink">Iniciar sesión</Link>
            ) : null}
            {location.pathname !== "/signup" ? (
                <Link to="/signup" className="appHeaderLink">Crear cuenta</Link>
            ) : null}
        </div>
    );
}
