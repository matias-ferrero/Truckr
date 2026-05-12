import { API_BASE_URL, getJwt } from "../api";

// Wire format mirrors VehicleResource (and VehicleSlimResource) on the backend.
export type VehiclePhoto = {
    id: number;
    thumbnail: string;
    card: string;
    full: string;
};

export type Vehicle = {
    id: number;
    carrier_id: number;
    make: string;
    model: string;
    year: number | null;
    plate: string;
    vehicle_type: string;
    max_load_kg: string;
    length_cm: number | null;
    width_cm: number | null;
    height_cm: number | null;
    volume_cm3: number | null;
    gps_enabled: boolean;
    description: string | null;
    photos: VehiclePhoto[];
    created_at: string;
    updated_at: string;
};

export type VehicleListMeta = {
    total: number;
    page: number;
    perPage: number;
    totalPages: number;
};

export type VehicleListResult = {
    items: Vehicle[];
    meta: VehicleListMeta;
};

// Bearer JWT auth (ADR-011). The token lives in localStorage and rides on
// every authenticated request. If absent, requests go out anonymous and
// the backend will return 401.
function authHeaders(): HeadersInit {
    const token = getJwt();
    return token ? { Authorization: `Bearer ${token}` } : {};
}

async function handle<T>(res: Response): Promise<T> {
    if (res.ok) return res.json() as Promise<T>;
    const body = await res.json().catch(() => ({ error: "request_failed" }));
    throw Object.assign(new Error(body.error ?? "request_failed"), {
        status: res.status,
        body,
    });
}

function metaFromHeaders(res: Response): VehicleListMeta {
    return {
        total: Number(res.headers.get("X-Total") ?? 0),
        page: Number(res.headers.get("X-Page") ?? 1),
        perPage: Number(res.headers.get("X-Per-Page") ?? 20),
        totalPages: Number(res.headers.get("X-Total-Pages") ?? 1),
    };
}

export async function listMyVehicles(page = 1): Promise<VehicleListResult> {
    const res = await fetch(`${API_BASE_URL}/api/carriers/me/vehicles?page=${page}`, {
        headers: { Accept: "application/json", ...authHeaders() },
    });
    if (!res.ok) {
        await handle(res);
    }
    const items = (await res.json()) as Vehicle[];
    return { items, meta: metaFromHeaders(res) };
}

export async function getMyVehicle(id: number): Promise<Vehicle> {
    const res = await fetch(`${API_BASE_URL}/api/carriers/me/vehicles/${id}`, {
        headers: { Accept: "application/json", ...authHeaders() },
    });
    return handle<Vehicle>(res);
}

export async function createVehicle(form: FormData): Promise<Vehicle> {
    const res = await fetch(`${API_BASE_URL}/api/carriers/me/vehicles`, {
        method: "POST",
        body: form,
        headers: { ...authHeaders() },
    });
    return handle<Vehicle>(res);
}

export async function updateVehicle(id: number, form: FormData): Promise<Vehicle> {
    const res = await fetch(`${API_BASE_URL}/api/carriers/me/vehicles/${id}`, {
        method: "PATCH",
        body: form,
        headers: { ...authHeaders() },
    });
    return handle<Vehicle>(res);
}

export async function deleteVehicle(id: number): Promise<void> {
    const res = await fetch(`${API_BASE_URL}/api/carriers/me/vehicles/${id}`, {
        method: "DELETE",
        headers: { ...authHeaders() },
    });
    if (!res.ok && res.status !== 204) {
        await handle(res);
    }
}
