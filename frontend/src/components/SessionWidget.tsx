import { Link, useLocation, useNavigate } from "react-router-dom";
import { useCurrentUser } from "../auth/useCurrentUser";
import { Button } from "./ui/button";

/**
 * Auth-state chip used by both the dashboard `Header` and the landing
 * topbar. Renders the user's display name + logout when signed in, or
 * login / register links otherwise. Carriers get a link to their public
 * profile; shippers see a non-interactive name chip (no profile screen
 * exists for them yet).
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
        return (
            <div className="appHeaderActions">
                {me.roles.includes("carrier") ? (
                    <Link
                        to="/carriers/me"
                        className="appHeaderProfile"
                        aria-label={`Perfil público de ${displayName}`}
                    >
                        {displayName}
                    </Link>
                ) : (
                    <span
                        className="appHeaderProfile"
                        aria-label={`Sesión como ${displayName}`}
                    >
                        {displayName}
                    </span>
                )}
                <Link to="/profile" className="appHeaderLink">
                    Mi perfil
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
