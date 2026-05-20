/* Typed REST client for the Cargo publication funnel (US27 / REQ-BE-00032).
 *
 * Built on `apiFetch` (src/api.ts), which attaches the `Authorization: Bearer`
 * header automatically and normalises the `{ error: { code, message, details } }`
 * envelope into an `ApiError`. List endpoints need the Pagy headers, so those
 * use a raw `fetch` like the other list clients in the repo.
 */

import { apiFetch, API_BASE_URL, buildAuthHeaders, ApiError } from "../../api";
import type { Cargo, CargoDraft, CargoMatch, CargoStatus } from "../../types/Cargo";

export type CargoListMeta = {
    total: number;
    page: number;
    perPage: number;
    totalPages: number;
};

export type CargoListResult = {
    items: Cargo[];
    meta: CargoListMeta;
};

export type CargoMatchListResult = {
    items: CargoMatch[];
    meta: CargoListMeta;
};

function metaFromHeaders(res: Response): CargoListMeta {
    return {
        total: Number(res.headers.get("X-Total") ?? 0),
        page: Number(res.headers.get("X-Page") ?? 1),
        perPage: Number(res.headers.get("X-Per-Page") ?? 20),
        totalPages: Number(res.headers.get("X-Total-Pages") ?? 1),
    };
}

/** Raises an `ApiError` from a non-ok list response (Pagy endpoints). */
async function rejectList(res: Response): Promise<never> {
    let payload: { error?: { code?: string; message?: string; details?: unknown } } = {};
    try {
        payload = await res.json();
    } catch {
        /* body wasn't JSON */
    }
    throw new ApiError(
        res.status,
        payload.error?.message ?? `HTTP ${res.status}`,
        payload.error?.code,
        payload.error?.details,
    );
}

/** GET /api/cargos — the signed-in Shipper's cargos, optionally status-filtered. */
export async function listCargos(
    status?: CargoStatus,
    page = 1,
): Promise<CargoListResult> {
    const qs = new URLSearchParams({ page: String(page) });
    if (status) qs.set("status", status);
    const res = await fetch(`${API_BASE_URL}/api/cargos?${qs.toString()}`, {
        headers: { Accept: "application/json", ...buildAuthHeaders() },
    });
    if (!res.ok) await rejectList(res);
    const items = (await res.json()) as Cargo[];
    return { items, meta: metaFromHeaders(res) };
}

/** GET /api/cargos/:id — a single Cargo with its nested offers. */
export async function getCargo(id: number): Promise<Cargo> {
    return apiFetch<Cargo>(`/api/cargos/${id}`);
}

/** POST /api/cargos — publish a new Cargo. Response embeds the initial matches. */
export async function createCargo(draft: CargoDraft): Promise<Cargo> {
    return apiFetch<Cargo>("/api/cargos", {
        method: "POST",
        body: { cargo: serializeDraft(draft) },
    });
}

/** PATCH /api/cargos/:id — edit an `open` Cargo with no accepted offer. */
export async function updateCargo(id: number, draft: CargoDraft): Promise<Cargo> {
    return apiFetch<Cargo>(`/api/cargos/${id}`, {
        method: "PATCH",
        body: { cargo: serializeDraft(draft) },
    });
}

/** DELETE /api/cargos/:id — soft-cancel; expires pending sibling offers. */
export async function cancelCargo(id: number, reason?: string): Promise<void> {
    await apiFetch<void>(`/api/cargos/${id}`, {
        method: "DELETE",
        body: reason ? { reason } : undefined,
    });
}

/** GET /api/cargos/:id/matches — zone-compatible transport windows. */
export async function getMatches(
    id: number,
    page = 1,
): Promise<CargoMatchListResult> {
    const res = await fetch(
        `${API_BASE_URL}/api/cargos/${id}/matches?page=${page}`,
        { headers: { Accept: "application/json", ...buildAuthHeaders() } },
    );
    if (!res.ok) await rejectList(res);
    const items = (await res.json()) as CargoMatch[];
    return { items, meta: metaFromHeaders(res) };
}

/**
 * Maps the `details` of an `ApiError` (the `{ field: ["msg", ...] }` envelope)
 * into a flat `{ field: "first message" }` map for inline form errors.
 */
export function fieldErrorsFrom(err: unknown): Record<string, string> {
    if (!(err instanceof ApiError) || !err.details || typeof err.details !== "object") {
        return {};
    }
    const out: Record<string, string> = {};
    for (const [key, value] of Object.entries(err.details as Record<string, unknown>)) {
        if (Array.isArray(value) && value.length > 0) out[key] = String(value[0]);
    }
    return out;
}

/** Drops empty optional fields (volume) so the backend treats them as nil. */
function serializeDraft(draft: CargoDraft): Record<string, string> {
    const { volume_cm3, ...rest } = draft;
    const body: Record<string, string> = { ...rest };
    if (volume_cm3.trim() !== "") body.volume_cm3 = volume_cm3;
    return body;
}
