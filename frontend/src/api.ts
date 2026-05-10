// Derive the API origin from the current page so the session cookie stays
// same-site (e.g. browser at 127.0.0.1:5173 → API at 127.0.0.1:3000).
// Cross-site requests would block the SameSite=Lax session cookie and break
// CSRF. Override with VITE_API_BASE_URL when needed.
function defaultApiBase(): string {
    if (typeof window !== "undefined" && window.location?.hostname) {
        return `${window.location.protocol}//${window.location.hostname}:3000`;
    }
    return "http://localhost:3000";
}

export const API_BASE_URL =
    (import.meta.env.VITE_API_BASE_URL as string | undefined) ?? defaultApiBase();

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
    csrfToken?: string | null;
    signal?: AbortSignal;
};

/**
 * Fetch wrapper that:
 *  - sends/receives the cross-origin session cookie (`credentials: include`)
 *  - attaches the X-CSRF-Token header for unsafe methods when provided
 *  - normalizes the JSON error envelope into an ApiError
 *
 * Returns the parsed JSON body or undefined on 204 No Content.
 */
export async function apiFetch<T = unknown>(path: string, opts: ApiOpts = {}): Promise<T> {
    const headers: Record<string, string> = { "Content-Type": "application/json" };
    if (opts.csrfToken) headers["X-CSRF-Token"] = opts.csrfToken;

    const res = await fetch(`${API_BASE_URL}${path}`, {
        method: opts.method ?? "GET",
        credentials: "include",
        headers,
        body: opts.body !== undefined ? JSON.stringify(opts.body) : undefined,
        signal: opts.signal,
    });

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
