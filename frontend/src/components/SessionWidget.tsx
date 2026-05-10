import { Link, useNavigate } from "react-router-dom";
import { useCurrentUser } from "../auth/useCurrentUser";

/**
 * Compact session widget meant to drop into existing layouts (e.g. the
 * landing topbar). Renders the email + logout button when authenticated,
 * or login/register links otherwise. Shows nothing while bootstrapping
 * to avoid layout flash.
 */
export function SessionWidget() {
    const { me, loading, logout } = useCurrentUser();
    const navigate = useNavigate();

    if (loading) return <span className="appHeaderEmail" aria-hidden="true">…</span>;

    const onLogout = async () => {
        try {
            await logout();
        } finally {
            navigate("/login");
        }
    };

    if (me) {
        return (
            <div className="appHeaderActions">
                <span className="appHeaderEmail" aria-label={`Sesión como ${me.email}`}>
                    {me.email}
                </span>
                <button type="button" className="appHeaderButton" onClick={onLogout}>
                    Salir
                </button>
            </div>
        );
    }

    return (
        <div className="appHeaderActions">
            <Link to="/login" className="appHeaderLink">Iniciar sesión</Link>
            <Link to="/signup" className="appHeaderLink">Crear cuenta</Link>
        </div>
    );
}
