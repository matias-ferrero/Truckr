import { Link, useLocation, useNavigate } from "react-router-dom";
import { useCurrentUser } from "../auth/useCurrentUser";

export function Header() {
    const { me, loading, logout } = useCurrentUser();
    const navigate = useNavigate();
    const location = useLocation();

    const onLogout = async () => {
        try {
            await logout();
        } finally {
            navigate("/login");
        }
    };

    return (
        <header className="appHeader" role="banner">
            <div className="appHeaderInner">
                <Link to="/" className="appHeaderBrand" aria-label="Truckr — Inicio">
                    Truckr®
                </Link>

                <nav className="appHeaderActions" aria-label="Sesión">
                    {loading ? (
                        <span className="appHeaderEmail" aria-hidden="true">…</span>
                    ) : me ? (
                        <>
                            <span className="appHeaderEmail" aria-label={`Sesión como ${me.email}`}>
                                {me.email}
                            </span>
                            <button
                                type="button"
                                className="appHeaderButton"
                                onClick={onLogout}
                            >
                                Salir
                            </button>
                        </>
                    ) : (
                        <>
                            {location.pathname !== "/login" ? (
                                <Link to="/login" className="appHeaderLink">Iniciar sesión</Link>
                            ) : null}
                            {location.pathname !== "/signup" ? (
                                <Link to="/signup" className="appHeaderLink">Crear cuenta</Link>
                            ) : null}
                        </>
                    )}
                </nav>
            </div>
        </header>
    );
}
