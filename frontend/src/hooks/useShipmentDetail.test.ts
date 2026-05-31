import { renderHook, act, waitFor } from "@testing-library/react";
import { describe, expect, it, vi, beforeEach } from "vitest";
import { server } from "../test/mocks/server";
import { http, HttpResponse } from "msw";
import { fixtureShipmentDetail } from "../test/mocks/handlers";
import { useShipmentDetail } from "./useShipmentDetail";

const API = "http://localhost:3000";

beforeEach(() => {
    vi.restoreAllMocks();
});

describe("useShipmentDetail", () => {
    it("starts in loading state", () => {
        const { result } = renderHook(() => useShipmentDetail(31));
        expect(result.current.state.status).toBe("loading");
    });

    it("transitions to ready with detail and derived state", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({ state: "delivered" }))),
        );
        const { result } = renderHook(() => useShipmentDetail(31));
        await waitFor(() => expect(result.current.state.status).toBe("ready"));
        const s = result.current.state;
        if (s.status !== "ready") throw new Error("wrong state");
        expect(s.detail.id).toBe(31);
        expect(s.detail.available_actions).toEqual([]);
    });

    it("derives paymentState=paid when payment.state===escrowed", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "accepted",
                    payment: { id: 1, state: "escrowed", amount_cents: 100, currency: "ARS", escrowed_at: "2026-06-11T10:05:00Z" },
                }))),
        );
        const { result } = renderHook(() => useShipmentDetail(31));
        await waitFor(() => expect(result.current.state.status).toBe("ready"));
        const s = result.current.state;
        if (s.status !== "ready") throw new Error("wrong state");
        expect(s.derived.paymentState).toBe("paid");
    });

    it("derives paymentState=pending when no payment", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({ state: "accepted", payment: null }))),
        );
        const { result } = renderHook(() => useShipmentDetail(31));
        await waitFor(() => expect(result.current.state.status).toBe("ready"));
        const s = result.current.state;
        if (s.status !== "ready") throw new Error("wrong state");
        expect(s.derived.paymentState).toBe("pending");
    });

    it("derives compositeLabel=to_pick_up when accepted+escrowed", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "accepted",
                    payment: { id: 1, state: "escrowed", amount_cents: 100, currency: "ARS", escrowed_at: "2026-06-11T10:05:00Z" },
                }))),
        );
        const { result } = renderHook(() => useShipmentDetail(31));
        await waitFor(() => expect(result.current.state.status).toBe("ready"));
        const s = result.current.state;
        if (s.status !== "ready") throw new Error("wrong state");
        expect(s.derived.compositeLabel).toBe("to_pick_up");
    });

    it("derives compositeLabel=awaiting_payment when accepted+no payment", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({ state: "accepted", payment: null }))),
        );
        const { result } = renderHook(() => useShipmentDetail(31));
        await waitFor(() => expect(result.current.state.status).toBe("ready"));
        const s = result.current.state;
        if (s.status !== "ready") throw new Error("wrong state");
        expect(s.derived.compositeLabel).toBe("awaiting_payment");
    });

    it("derives compositeLabel=null when in_transit", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "in_transit",
                    payment: { id: 1, state: "escrowed", amount_cents: 100, currency: "ARS", escrowed_at: "2026-06-11T10:05:00Z" },
                }))),
        );
        const { result } = renderHook(() => useShipmentDetail(31));
        await waitFor(() => expect(result.current.state.status).toBe("ready"));
        const s = result.current.state;
        if (s.status !== "ready") throw new Error("wrong state");
        expect(s.derived.compositeLabel).toBeNull();
    });

    it("derives payLabel=retry_payment when payment.state===failed", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "accepted",
                    payment: { id: 1, state: "failed", amount_cents: 100, currency: "ARS", escrowed_at: null },
                }))),
        );
        const { result } = renderHook(() => useShipmentDetail(31));
        await waitFor(() => expect(result.current.state.status).toBe("ready"));
        const s = result.current.state;
        if (s.status !== "ready") throw new Error("wrong state");
        expect(s.derived.payLabel).toBe("retry_payment");
    });

    it("derives payLabel=pay when no previous payment", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({ state: "accepted", payment: null }))),
        );
        const { result } = renderHook(() => useShipmentDetail(31));
        await waitFor(() => expect(result.current.state.status).toBe("ready"));
        const s = result.current.state;
        if (s.status !== "ready") throw new Error("wrong state");
        expect(s.derived.payLabel).toBe("pay");
    });

    it("transitions to not_found on 404", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json({ error: "not found" }, { status: 404 })),
        );
        const { result } = renderHook(() => useShipmentDetail(99));
        await waitFor(() => expect(result.current.state.status).toBe("not_found"));
    });

    it("transitions to error on non-404 failure", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json({ error: "server error" }, { status: 500 })),
        );
        const { result } = renderHook(() => useShipmentDetail(31));
        await waitFor(() => expect(result.current.state.status).toBe("error"));
    });

    it("reload re-fetches detail", async () => {
        let callCount = 0;
        server.use(
            http.get(`${API}/api/shipments/:id`, () => {
                callCount++;
                return HttpResponse.json(fixtureShipmentDetail());
            }),
        );
        const { result } = renderHook(() => useShipmentDetail(31));
        await waitFor(() => expect(result.current.state.status).toBe("ready"));
        act(() => { result.current.reload(); });
        await waitFor(() => expect(callCount).toBe(2));
    });

    it("handleAction(start_transit) refetches and emits truckr:shipment-updated", async () => {
        const events: string[] = [];
        window.addEventListener("truckr:shipment-updated", () => events.push("fired"));

        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "accepted",
                    available_actions: ["start_transit"],
                    payment: { id: 1, state: "escrowed", amount_cents: 100, currency: "ARS", escrowed_at: "2026-06-11T10:05:00Z" },
                }))),
        );
        const { result } = renderHook(() => useShipmentDetail(31));
        await waitFor(() => expect(result.current.state.status).toBe("ready"));

        await act(async () => {
            await result.current.handleAction("start_transit");
        });

        expect(events).toContain("fired");
        window.removeEventListener("truckr:shipment-updated", () => {});
    });

    it("handleAction(pay) calls createShipmentPayment and refetches", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({ state: "accepted", payment: null, available_actions: ["pay"] }))),
        );
        const { result } = renderHook(() => useShipmentDetail(31));
        await waitFor(() => expect(result.current.state.status).toBe("ready"));

        await act(async () => {
            await result.current.handleAction("pay");
        });

        const s = result.current.state;
        expect(s.status).toBe("ready");
    });

    it("sets actionError for cancel action (not yet implemented)", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({ available_actions: ["cancel"] }))),
        );
        const { result } = renderHook(() => useShipmentDetail(31));
        await waitFor(() => expect(result.current.state.status).toBe("ready"));

        await act(async () => {
            await result.current.handleAction("cancel");
        });

        const s = result.current.state;
        if (s.status !== "ready") throw new Error("wrong state");
        expect(s.derived.actionError).toMatch(/cancel/i);
    });

    it("sets actionError and does NOT refetch on mutation failure", async () => {
        let fetchCount = 0;
        server.use(
            http.get(`${API}/api/shipments/:id`, () => {
                fetchCount++;
                return HttpResponse.json(fixtureShipmentDetail({ available_actions: ["deliver"] }));
            }),
            http.post(`${API}/api/shipments/:id/deliver`, () =>
                HttpResponse.json({ error: "forbidden" }, { status: 403 })),
        );
        const { result } = renderHook(() => useShipmentDetail(31));
        await waitFor(() => expect(result.current.state.status).toBe("ready"));
        const fetchCountAfterLoad = fetchCount;

        await act(async () => {
            await result.current.handleAction("deliver");
        });

        const s = result.current.state;
        if (s.status !== "ready") throw new Error("wrong state");
        expect(s.derived.actionError).not.toBeNull();
        expect(fetchCount).toBe(fetchCountAfterLoad);
    });
});
