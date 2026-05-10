import { createContext, useEffect, useState, type ReactNode } from "react";
import { ApiError, apiFetch } from "../api";

export type Role = "carrier" | "shipper";

export type Me = {
    id: number;
    email: string;
    full_name?: string | null;
    phone?: string | null;
    verified_at?: string | null;
    roles: Role[];
    carrier?: unknown;
    shipper?: unknown;
};

export type RegisterInput = {
    email: string;
    password: string;
    name: string;
    role: "carrier" | "shipper";
};

export type LoginInput = { email: string; password: string };

export type AuthState = {
    me: Me | null;
    loading: boolean;
    csrfToken: string | null;
    register: (input: RegisterInput) => Promise<void>;
    login: (input: LoginInput) => Promise<void>;
    logout: () => Promise<void>;
};

export const AuthContext = createContext<AuthState | undefined>(undefined);

async function fetchCsrf(): Promise<string> {
    const r = await apiFetch<{ csrf_token: string }>("/api/auth/csrf");
    return r.csrf_token;
}

export function AuthProvider({ children }: { children: ReactNode }) {
    const [me, setMe] = useState<Me | null>(null);
    const [loading, setLoading] = useState(true);
    const [csrfToken, setCsrfToken] = useState<string | null>(null);

    useEffect(() => {
        let cancelled = false;
        (async () => {
            try {
                const token = await fetchCsrf();
                if (cancelled) return;
                setCsrfToken(token);
                try {
                    const meRes = await apiFetch<Me>("/api/auth/me");
                    if (!cancelled) setMe(meRes);
                } catch (err) {
                    if (!(err instanceof ApiError) || err.status !== 401) throw err;
                }
            } catch (err) {
                console.error("Auth bootstrap failed", err);
            } finally {
                if (!cancelled) setLoading(false);
            }
        })();
        return () => {
            cancelled = true;
        };
    }, []);

    const ensureToken = async () => {
        if (csrfToken) return csrfToken;
        const t = await fetchCsrf();
        setCsrfToken(t);
        return t;
    };

    const register: AuthState["register"] = async (input) => {
        const token = await ensureToken();
        const next = await apiFetch<Me>("/api/auth/register", {
            method: "POST",
            body: input,
            csrfToken: token,
        });
        setMe(next);
    };

    const login: AuthState["login"] = async (input) => {
        const token = await ensureToken();
        const next = await apiFetch<Me>("/api/auth/login", {
            method: "POST",
            body: input,
            csrfToken: token,
        });
        setMe(next);
    };

    const logout: AuthState["logout"] = async () => {
        const token = await ensureToken();
        await apiFetch<void>("/api/auth/logout", { method: "DELETE", csrfToken: token });
        setMe(null);
        // Refresh CSRF token: logout reset_session invalidates the previous one.
        try {
            const fresh = await fetchCsrf();
            setCsrfToken(fresh);
        } catch {
            setCsrfToken(null);
        }
    };

    return (
        <AuthContext.Provider value={{ me, loading, csrfToken, register, login, logout }}>
            {children}
        </AuthContext.Provider>
    );
}
