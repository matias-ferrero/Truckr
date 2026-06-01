import { Link, useLocation, useNavigate } from "react-router-dom";
import { useCurrentUser } from "../auth/useCurrentUser";
import { Button } from "./ui/button";

/**
 * Auth-state chip used by both the dashboard `Header` and the landing
 * topbar. The user's name acts as the single profile entry point: each
 * role goes to its public profile (carriers → /carriers/me, shippers →
 * /shippers/me), which links to /profile for edit. Anonymous users see
 * login / register links instead.
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
        // Both roles now have a public profile show page: carriers at
        // /carriers/me, shippers at /shippers/me (each redirects to the
        // canonical /:role/:id). The public profile is the single entry
        // point and links to /profile for editing.
        const profileHref = isCarrier ? "/carriers/me" : "/shippers/me";
        const profileLabel = `Perfil público de ${displayName}`;
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
