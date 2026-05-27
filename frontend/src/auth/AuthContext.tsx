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

export type UpdateProfileInput = {
    name?: string;
    email?: string;
    phone?: string;
};

export type AuthState = {
    me: Me | null;
    loading: boolean;
    register: (input: RegisterInput) => Promise<void>;
    login: (input: LoginInput) => Promise<void>;
    logout: () => Promise<void>;
    updateMe: (input: UpdateProfileInput) => Promise<Me>;
};

export const AuthContext = createContext<AuthState | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
    const [me, setMe] = useState<Me | null>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        let cancelled = false;
        // Snapshot the token before the async fetch so we can detect if a
        // concurrent flow (e.g. the impersonation page storing a new JWT via
        // setJwt just before window.location.replace) replaces it while the
        // request is in-flight. Without this guard, clearJwt() would wipe the
        // freshly stored impersonation token when the anonymous bootstrap 401
        // resolves after the new token has already been saved.
        const tokenAtMount = getJwt();
        (async () => {
            try {
                // Bootstrap: probe /me. If a JWT is in storage, apiFetch
                // attaches it; otherwise the request goes anonymous and
                // the backend returns 401 — both branches are normal.
                const meRes = await apiFetch<Me>("/api/auth/me");
                if (!cancelled) setMe(meRes);
            } catch (err) {
                if (err instanceof ApiError && err.status === 401) {
                    // Only clear the token if it is still the same one we sent
                    // and the component is still mounted. If another flow has
                    // since stored a fresh token (impersonation race), leave it.
                    if (!cancelled && getJwt() === tokenAtMount) clearJwt();
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

    const updateMe: AuthState["updateMe"] = async (input) => {
        // PATCH /api/auth/me — wire shape mirrors register (`name` instead
        // of `full_name`). The backend echoes back a full MeResource, so
        // we refresh local state from the response rather than merging
        // optimistically: roles, verified_at, and nested carrier/shipper
        // can change as a side-effect of the patch (email reset, etc.).
        const next = await apiFetch<Me>("/api/auth/me", {
            method: "PATCH",
            body: input,
        });
        setMe(next);
        return next;
    };

    return (
        <AuthContext.Provider value={{ me, loading, register, login, logout, updateMe }}>
            {children}
        </AuthContext.Provider>
    );
}
