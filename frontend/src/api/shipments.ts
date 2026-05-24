import { API_BASE_URL, ApiError, buildAuthHeaders } from "../api";

export type ShipmentStatusFilter = "pending_payment" | "to_pick_up" | "in_transit" | "delivered";

export type CarrierShipment = {
    id: number;
    cargo_offer_id: number;
    status: ShipmentStatusFilter;
    accepted_at: string | null;
    picked_up_at: string | null;
    delivered_at: string | null;
    created_at: string;
    updated_at: string;
};

export type ShipmentListMeta = {
    total: number;
    page: number;
    perPage: number;
    totalPages: number;
};

export type ShipmentListResult = {
    items: CarrierShipment[];
    meta: ShipmentListMeta;
};

function metaFromHeaders(res: Response): ShipmentListMeta {
    return {
        total: Number(res.headers.get("X-Total") ?? 0),
        page: Number(res.headers.get("X-Page") ?? 1),
        perPage: Number(res.headers.get("X-Per-Page") ?? 20),
        totalPages: Number(res.headers.get("X-Total-Pages") ?? 1),
    };
}

async function ensureOk(res: Response): Promise<void> {
    if (res.ok) return;

    let payload: { error?: { code?: string; message?: string; details?: unknown } } = {};
    try {
        payload = await res.json();
    } catch {
        // ignore non-json responses
    }

    throw new ApiError(
        res.status,
        payload.error?.message ?? `HTTP ${res.status}`,
        payload.error?.code,
        payload.error?.details,
    );
}

export async function listCarrierShipments(
    status?: ShipmentStatusFilter,
    page = 1,
): Promise<ShipmentListResult> {
    const query = new URLSearchParams({ page: String(page) });
    if (status) query.set("status", status);

    const res = await fetch(`${API_BASE_URL}/api/carriers/me/shipments?${query.toString()}`, {
        headers: { Accept: "application/json", ...buildAuthHeaders() },
    });

    await ensureOk(res);
    const items = (await res.json()) as CarrierShipment[];
    return { items, meta: metaFromHeaders(res) };
}
