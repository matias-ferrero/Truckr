// Derive the API origin from the current page. Same-site lookups keep
// dev tooling (Vite at 5173 → Rails at 3000) wired without extra config.
// Override with VITE_API_BASE_URL when needed.
function defaultApiBase(): string {
    if (typeof window !== "undefined" && window.location?.hostname) {
        return `${window.location.protocol}//${window.location.hostname}:3000`;
    }
    return "http://localhost:3000";
}

export const API_BASE_URL =
    (import.meta.env.VITE_API_BASE_URL as string | undefined) ?? defaultApiBase();

// Stateless JWT (ADR-011). Tokens live in localStorage so they survive
// reloads; the backend dispatches the token via the `Authorization`
// response header on login/register, and we echo it back on every
// subsequent request.
const JWT_STORAGE_KEY = "truckr.jwt";

export function getJwt(): string | null {
    if (typeof window === "undefined") return null;
    return window.localStorage.getItem(JWT_STORAGE_KEY);
}

export function setJwt(token: string): void {
    if (typeof window === "undefined") return;
    window.localStorage.setItem(JWT_STORAGE_KEY, token);
}

export function clearJwt(): void {
    if (typeof window === "undefined") return;
    window.localStorage.removeItem(JWT_STORAGE_KEY);
}

// `Authorization: Bearer <jwt>` — three base64url segments separated by dots,
// optionally with a leading "Bearer ". devise-jwt sets the header with the
// scheme prefix; we accept either shape and strip it for storage.
function normalizeBearer(header: string): string {
    return header.replace(/^Bearer\s+/i, "").trim();
}

export class ApiError extends Error {
    public readonly status: number;
    public readonly code?: string;
    public readonly details?: unknown;

    constructor(status: number, message: string, code?: string, details?: unknown) {
        super(message);
        this.name = "ApiError";
        this.status = status;
        this.code = code;
        this.details = details;
    }
}

export type ApiOpts = {
    method?: "GET" | "POST" | "PUT" | "PATCH" | "DELETE";
    body?: unknown;
    signal?: AbortSignal;
};

/**
 * Fetch wrapper that:
 *  - attaches `Authorization: Bearer <jwt>` when a token is stored
 *  - captures the `Authorization` response header (devise-jwt dispatch)
 *    and stores the token automatically
 *  - normalizes the JSON error envelope into an ApiError
 *
 * Returns the parsed JSON body or undefined on 204 No Content.
 */
export async function apiFetch<T = unknown>(path: string, opts: ApiOpts = {}): Promise<T> {
    const headers: Record<string, string> = { "Content-Type": "application/json" };
    const token = getJwt();
    if (token) headers["Authorization"] = `Bearer ${token}`;

    const res = await fetch(`${API_BASE_URL}${path}`, {
        method: opts.method ?? "GET",
        headers,
        body: opts.body !== undefined ? JSON.stringify(opts.body) : undefined,
        signal: opts.signal,
    });

    // devise-jwt dispatches the token on successful login/register via the
    // Authorization response header. Capture it regardless of path — the
    // backend only sets it on the dispatch_requests it's configured for.
    const issued = res.headers.get("Authorization");
    if (res.ok && issued) {
        setJwt(normalizeBearer(issued));
    }

    if (!res.ok) {
        let payload: { error?: { code?: string; message?: string; details?: unknown } } = {};
        try {
            payload = await res.json();
        } catch {
            // body wasn't JSON — keep payload empty.
        }
        throw new ApiError(
            res.status,
            payload.error?.message ?? `HTTP ${res.status}`,
            payload.error?.code,
            payload.error?.details,
        );
    }

    if (res.status === 204) return undefined as T;
    return (await res.json()) as T;
}
