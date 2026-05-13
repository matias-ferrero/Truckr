import { useEffect, useState } from "react";
import { useLocation } from "react-router-dom";
import { setJwt } from "../api";

// Lands here after the AA "Impersonate" button redirects to
// `/impersonate#token=<jwt>`. The fragment never reaches the server, so the
// raw JWT does not appear in any access log between admin and SPA. We drop
// the token into the same localStorage key the rest of the app reads
// (`truckr.jwt`, see `src/api.ts`) and then hard-reload to `/` so the
// AuthProvider re-bootstraps with the new identity.
export default function ImpersonatePage() {
    const { hash } = useLocation();
    const [error, setError] = useState(false);

    useEffect(() => {
        const fragment = hash.startsWith("#") ? hash.slice(1) : hash;
        const params = new URLSearchParams(fragment);
        const token = (params.get("token") ?? "").trim();

        if (!token || !token.includes(".")) {
            setError(true);
            return;
        }

        // Wipe the fragment from the address bar so the raw token does not
        // linger in browser history / devtools after the redirect.
        if (typeof window !== "undefined" && window.location.hash) {
            window.history.replaceState(null, "", window.location.pathname);
        }

        setJwt(token);
        // Hard reload so AuthProvider re-runs its `/api/auth/me` bootstrap
        // against the new token. A client-side navigation would not refetch.
        window.location.replace("/");
    }, [hash]);

    if (error) {
        return (
            <main style={{ padding: "2rem", textAlign: "center" }}>
                <p>Impersonation failed: missing or invalid token.</p>
                <p>
                    <a href="/login">Go to login</a>
                </p>
            </main>
        );
    }

    return (
        <main style={{ padding: "2rem", textAlign: "center" }} aria-busy="true">
            <p>Impersonating…</p>
        </main>
    );
}
