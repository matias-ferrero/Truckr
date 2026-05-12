import { createContext, useEffect, useState, type ReactNode } from "react";
import { ApiError, apiFetch, clearJwt, getJwt } from "../api";

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
    register: (input: RegisterInput) => Promise<void>;
    login: (input: LoginInput) => Promise<void>;
    logout: () => Promise<void>;
};

export const AuthContext = createContext<AuthState | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
    const [me, setMe] = useState<Me | null>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        let cancelled = false;
        (async () => {
            try {
                // Bootstrap: probe /me. If a JWT is in storage, apiFetch
                // attaches it; otherwise the request goes anonymous and
                // the backend returns 401 — both branches are normal.
                const meRes = await apiFetch<Me>("/api/auth/me");
                if (!cancelled) setMe(meRes);
            } catch (err) {
                if (err instanceof ApiError && err.status === 401) {
                    // Stored token (if any) is no longer valid — drop it.
                    clearJwt();
                } else if (!cancelled) {
                    console.error("Auth bootstrap failed", err);
                }
            } finally {
                if (!cancelled) setLoading(false);
            }
        })();
        return () => {
            cancelled = true;
        };
    }, []);

    const register: AuthState["register"] = async (input) => {
        // apiFetch captures the Authorization response header into JWT
        // storage automatically (devise-jwt dispatch).
        const next = await apiFetch<Me>("/api/auth/register", {
            method: "POST",
            body: input,
        });
        setMe(next);
    };

    const login: AuthState["login"] = async (input) => {
        // Devise's :database_authenticatable reads `params[:user]`, so the
        // wire shape is nested.
        const next = await apiFetch<Me>("/api/auth/login", {
            method: "POST",
            body: { user: input },
        });
        setMe(next);
    };

    const logout: AuthState["logout"] = async () => {
        try {
            await apiFetch<void>("/api/auth/logout", { method: "DELETE" });
        } finally {
            // Drop local state regardless of network outcome — a 401 from
            // a server-side revocation race shouldn't leave us logged in.
            clearJwt();
            setMe(null);
        }
    };

    return (
        <AuthContext.Provider value={{ me, loading, register, login, logout }}>
            {children}
        </AuthContext.Provider>
    );
}
