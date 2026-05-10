import { describe, expect, it } from "vitest";
import { http, HttpResponse } from "msw";
import { server } from "../test/mocks/server";
import {
    createVehicle,
    deleteVehicle,
    getMyVehicle,
    listMyVehicles,
    updateVehicle,
    type Vehicle,
} from "./vehicles";

const API = "http://localhost:3000";

const sampleVehicle: Vehicle = {
    id: 7,
    carrier_id: 1,
    make: "Ford",
    model: "F-100",
    year: 2018,
    plate: "AB123CD",
    vehicle_type: "truck",
    max_load_kg: "1500",
    length_cm: 500,
    width_cm: 200,
    height_cm: 220,
    volume_cm3: 22_000_000,
    gps_enabled: true,
    description: null,
    photos: [],
    created_at: "2026-01-01T00:00:00Z",
    updated_at: "2026-01-02T00:00:00Z",
};

describe("api/vehicles", () => {
    it("listMyVehicles returns items + meta from response headers", async () => {
        server.use(
            http.get(`${API}/api/carriers/me/vehicles`, () =>
                HttpResponse.json([sampleVehicle], {
                    headers: {
                        "X-Total": "1",
                        "X-Page": "1",
                        "X-Per-Page": "20",
                        "X-Total-Pages": "1",
                    },
                })),
        );

        const result = await listMyVehicles();
        expect(result.items).toHaveLength(1);
        expect(result.items[0].plate).toBe("AB123CD");
        expect(result.meta).toEqual({ total: 1, page: 1, perPage: 20, totalPages: 1 });
    });

    it("listMyVehicles defaults missing meta headers to 0/1/20/1", async () => {
        server.use(
            http.get(`${API}/api/carriers/me/vehicles`, () => HttpResponse.json([])),
        );

        const result = await listMyVehicles(2);
        expect(result.items).toEqual([]);
        expect(result.meta).toEqual({ total: 0, page: 1, perPage: 20, totalPages: 1 });
    });

    it("listMyVehicles throws an Error with status when API returns non-OK", async () => {
        server.use(
            http.get(`${API}/api/carriers/me/vehicles`, () =>
                HttpResponse.json({ error: "boom" }, { status: 500 })),
        );

        await expect(listMyVehicles()).rejects.toMatchObject({
            message: "boom",
            status: 500,
        });
    });

    it("getMyVehicle returns the vehicle JSON", async () => {
        server.use(
            http.get(`${API}/api/carriers/me/vehicles/7`, () => HttpResponse.json(sampleVehicle)),
        );

        const v = await getMyVehicle(7);
        expect(v.id).toBe(7);
        expect(v.make).toBe("Ford");
    });

    it("getMyVehicle throws on 404", async () => {
        server.use(
            http.get(`${API}/api/carriers/me/vehicles/999`, () =>
                HttpResponse.json({ error: "not_found" }, { status: 404 })),
        );

        await expect(getMyVehicle(999)).rejects.toMatchObject({ status: 404 });
    });

    it("createVehicle POSTs FormData and returns the created vehicle", async () => {
        let receivedMethod = "";
        server.use(
            http.post(`${API}/api/carriers/me/vehicles`, ({ request }) => {
                receivedMethod = request.method;
                return HttpResponse.json(sampleVehicle, { status: 201 });
            }),
        );

        const form = new FormData();
        form.append("vehicle[make]", "Ford");

        const result = await createVehicle(form);
        expect(receivedMethod).toBe("POST");
        expect(result.id).toBe(7);
    });

    it("updateVehicle PATCHes FormData", async () => {
        let receivedMethod = "";
        server.use(
            http.patch(`${API}/api/carriers/me/vehicles/7`, ({ request }) => {
                receivedMethod = request.method;
                return HttpResponse.json({ ...sampleVehicle, plate: "ZZ999XX" });
            }),
        );

        const form = new FormData();
        form.append("vehicle[plate]", "ZZ999XX");

        const result = await updateVehicle(7, form);
        expect(receivedMethod).toBe("PATCH");
        expect(result.plate).toBe("ZZ999XX");
    });

    it("deleteVehicle resolves on 204", async () => {
        server.use(
            http.delete(`${API}/api/carriers/me/vehicles/7`, () => new HttpResponse(null, { status: 204 })),
        );

        await expect(deleteVehicle(7)).resolves.toBeUndefined();
    });

    it("deleteVehicle throws on non-204 error", async () => {
        server.use(
            http.delete(`${API}/api/carriers/me/vehicles/7`, () =>
                HttpResponse.json({ error: "forbidden" }, { status: 403 })),
        );

        await expect(deleteVehicle(7)).rejects.toMatchObject({ status: 403 });
    });

    it("attaches X-Stub-Carrier-Id header when localStorage carries a stub id", async () => {
        let stubHeader: string | null = null;
        server.use(
            http.get(`${API}/api/carriers/me/vehicles`, ({ request }) => {
                stubHeader = request.headers.get("X-Stub-Carrier-Id");
                return HttpResponse.json([]);
            }),
        );

        window.localStorage.setItem("truckr.stubCarrierId", "42");
        try {
            await listMyVehicles();
            expect(stubHeader).toBe("42");
        } finally {
            window.localStorage.removeItem("truckr.stubCarrierId");
        }
    });
});
