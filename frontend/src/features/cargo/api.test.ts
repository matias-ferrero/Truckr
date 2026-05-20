import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
    cancelCargo,
    createCargo,
    fieldErrorsFrom,
    getCargo,
    getMatches,
    listCargos,
    updateCargo,
} from "./api";
import { ApiError } from "../../api";
import type { CargoDraft } from "../../types/Cargo";

const BASE = "http://localhost:3000";

function mockFetch(body: unknown, status = 200, headers: Record<string, string> = {}) {
    const init: ResponseInit = {
        status,
        headers: { "Content-Type": "application/json", ...headers },
    };
    const res = status === 204
        ? new Response(null, init)
        : new Response(JSON.stringify(body), init);
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(res));
}

const draft: CargoDraft = {
    cargo_description: "Pallets",
    pickup_address: "Calle 1",
    delivery_address: "Calle 2",
    pickup_zone: "Buenos Aires",
    delivery_zone: "Córdoba",
    pickup_window_start: "2026-06-01T08:00",
    pickup_window_end: "2026-06-03T18:00",
    weight_kg: "1500",
    volume_cm3: "3000000",
    declared_value_cents: "5000000",
};

beforeEach(() => {
    vi.unstubAllGlobals();
});

// The last test in this file leaves a `fetch` stub active otherwise, which
// leaks into unrelated suites (e.g. ImpersonatePage).
afterEach(() => {
    vi.unstubAllGlobals();
});

describe("listCargos", () => {
    it("returns items + meta from Pagy headers", async () => {
        mockFetch([{ id: 1 }], 200, { "X-Total": "3", "X-Total-Pages": "1" });
        const res = await listCargos();
        expect(res.items).toHaveLength(1);
        expect(res.meta.total).toBe(3);
    });

    it("appends the status filter to the query string", async () => {
        mockFetch([], 200);
        await listCargos("open", 2);
        const url = vi.mocked(fetch).mock.calls[0][0] as string;
        expect(url).toContain("status=open");
        expect(url).toContain("page=2");
    });

    it("omits the status param when no filter is given", async () => {
        mockFetch([], 200);
        await listCargos();
        const url = vi.mocked(fetch).mock.calls[0][0] as string;
        expect(url).not.toContain("status=");
    });

    it("raises an ApiError on a non-ok response", async () => {
        mockFetch({ error: { message: "boom", code: "x" } }, 500);
        await expect(listCargos()).rejects.toBeInstanceOf(ApiError);
    });

    it("raises an ApiError when the error body is not JSON", async () => {
        vi.stubGlobal(
            "fetch",
            vi.fn().mockResolvedValue(new Response("nope", { status: 502 })),
        );
        await expect(listCargos()).rejects.toMatchObject({ status: 502 });
    });
});

describe("getCargo", () => {
    it("GETs /api/cargos/:id", async () => {
        mockFetch({ id: 7 });
        const cargo = await getCargo(7);
        expect(cargo.id).toBe(7);
        expect(vi.mocked(fetch).mock.calls[0][0]).toBe(`${BASE}/api/cargos/7`);
    });
});

describe("createCargo / updateCargo", () => {
    it("POSTs the draft wrapped in `cargo`", async () => {
        mockFetch({ id: 9 }, 201);
        await createCargo(draft);
        const init = vi.mocked(fetch).mock.calls[0][1] as RequestInit;
        const body = JSON.parse(init.body as string);
        expect(init.method).toBe("POST");
        expect(body.cargo.cargo_description).toBe("Pallets");
        expect(body.cargo.volume_cm3).toBe("3000000");
    });

    it("drops an empty volume so the backend treats it as nil", async () => {
        mockFetch({ id: 9 }, 201);
        await createCargo({ ...draft, volume_cm3: "" });
        const init = vi.mocked(fetch).mock.calls[0][1] as RequestInit;
        const body = JSON.parse(init.body as string);
        expect(body.cargo).not.toHaveProperty("volume_cm3");
    });

    it("PATCHes /api/cargos/:id", async () => {
        mockFetch({ id: 4 });
        await updateCargo(4, draft);
        const init = vi.mocked(fetch).mock.calls[0][1] as RequestInit;
        expect(init.method).toBe("PATCH");
        expect(vi.mocked(fetch).mock.calls[0][0]).toBe(`${BASE}/api/cargos/4`);
    });
});

describe("cancelCargo", () => {
    it("DELETEs with the reason in the body", async () => {
        mockFetch(null, 204);
        await cancelCargo(3, "ya no la necesito");
        const init = vi.mocked(fetch).mock.calls[0][1] as RequestInit;
        expect(init.method).toBe("DELETE");
        expect(JSON.parse(init.body as string)).toEqual({
            reason: "ya no la necesito",
        });
    });

    it("DELETEs without a body when no reason is given", async () => {
        mockFetch(null, 204);
        await cancelCargo(3);
        const init = vi.mocked(fetch).mock.calls[0][1] as RequestInit;
        expect(init.body).toBeUndefined();
    });
});

describe("getMatches", () => {
    it("GETs /api/cargos/:id/matches with the page param", async () => {
        mockFetch([{ id: 5 }], 200, { "X-Total": "1" });
        const res = await getMatches(7, 2);
        expect(res.items).toHaveLength(1);
        const url = vi.mocked(fetch).mock.calls[0][0] as string;
        expect(url).toBe(`${BASE}/api/cargos/7/matches?page=2`);
    });

    it("raises an ApiError on a non-ok response", async () => {
        mockFetch({ error: { message: "boom" } }, 500);
        await expect(getMatches(7)).rejects.toBeInstanceOf(ApiError);
    });
});

describe("fieldErrorsFrom", () => {
    it("flattens an ApiError details map to first messages", () => {
        const err = new ApiError(422, "x", "x", {
            weight_kg: ["debe ser positivo"],
            pickup_zone: ["es requerida", "otro"],
        });
        expect(fieldErrorsFrom(err)).toEqual({
            weight_kg: "debe ser positivo",
            pickup_zone: "es requerida",
        });
    });

    it("returns {} for a non-ApiError", () => {
        expect(fieldErrorsFrom(new Error("nope"))).toEqual({});
    });

    it("returns {} when details is absent", () => {
        expect(fieldErrorsFrom(new ApiError(500, "x"))).toEqual({});
    });
});
