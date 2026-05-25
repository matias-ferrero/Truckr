import { API_BASE_URL, getJwt } from "../api";

export type TransportWindowVehicle = {
    id: number;
    make: string;
    model: string;
    plate: string;
    vehicle_type: string;
};

export type TransportWindow = {
    id: number;
    vehicle_id: number;
    origin_province: string;
    origin_locality: string | null;
    destination_province: string | null;
    destination_locality: string | null;
    price_per_km: string;
    max_km: number;
    available_from: string;
    available_to: string;
    active: boolean;
    cargo_offers_count: number;
    vehicle: TransportWindowVehicle;
    created_at: string;
    updated_at: string;
};

export type TransportWindowListMeta = {
    total: number;
    page: number;
    perPage: number;
    totalPages: number;
};

export type TransportWindowListResult = {
    items: TransportWindow[];
    meta: TransportWindowListMeta;
};

export type TransportWindowDraft = {
    vehicle_id: number;
    origin_province: string;
    origin_locality: string | null;
    destination_province: string | null;
    destination_locality: string | null;
    price_per_km: string;
    max_km: string;
    available_from: string;
    available_to: string;
};

export type TransportWindowPatch = Partial<Omit<TransportWindowDraft, "vehicle_id">> & {
    active?: boolean;
};

async function handle<T>(res: Response): Promise<T> {
    if (res.ok) return res.json() as Promise<T>;
    const body = await res.json().catch(() => ({ error: "request_failed" }));
    throw Object.assign(new Error(body?.error?.message ?? body?.error ?? "request_failed"), {
        status: res.status,
        body,
    });
}

function metaFromHeaders(res: Response): TransportWindowListMeta {
    return {
        total:      Number(res.headers.get("X-Total")       ?? 0),
        page:       Number(res.headers.get("X-Page")        ?? 1),
        perPage:    Number(res.headers.get("X-Per-Page")    ?? 20),
        totalPages: Number(res.headers.get("X-Total-Pages") ?? 1),
    };
}

function authHeaders(): HeadersInit {
    const token = getJwt();
    return token ? { Authorization: `Bearer ${token}` } : {};
}

export async function listMyTransportWindows(page = 1): Promise<TransportWindowListResult> {
    const res = await fetch(`${API_BASE_URL}/api/carriers/me/transport_windows?page=${page}`, {
        headers: { Accept: "application/json", ...authHeaders() },
    });
    if (!res.ok) await handle(res);
    const items = (await res.json()) as TransportWindow[];
    return { items, meta: metaFromHeaders(res) };
}

export async function getMyTransportWindow(id: number): Promise<TransportWindow> {
    const res = await fetch(`${API_BASE_URL}/api/carriers/me/transport_windows/${id}`, {
        headers: { Accept: "application/json", ...authHeaders() },
    });
    return handle<TransportWindow>(res);
}

export async function createTransportWindow(draft: TransportWindowDraft): Promise<TransportWindow> {
    const res = await fetch(`${API_BASE_URL}/api/carriers/me/transport_windows`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            Accept: "application/json",
            ...authHeaders(),
        },
        body: JSON.stringify({ transport_window: draft }),
    });
    return handle<TransportWindow>(res);
}

export async function updateTransportWindow(id: number, patch: TransportWindowPatch): Promise<TransportWindow> {
    const res = await fetch(`${API_BASE_URL}/api/carriers/me/transport_windows/${id}`, {
        method: "PATCH",
        headers: {
            "Content-Type": "application/json",
            Accept: "application/json",
            ...authHeaders(),
        },
        body: JSON.stringify({ transport_window: patch }),
    });
    return handle<TransportWindow>(res);
}

export async function deactivateTransportWindow(id: number): Promise<TransportWindow> {
    return updateTransportWindow(id, { active: false });
}

export async function deleteTransportWindow(id: number): Promise<void> {
    const res = await fetch(`${API_BASE_URL}/api/carriers/me/transport_windows/${id}`, {
        method: "DELETE",
        headers: { Accept: "application/json", ...authHeaders() },
    });
    if (!res.ok && res.status !== 204) await handle(res);
}
