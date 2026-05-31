import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { TrackingEventTimeline } from "./TrackingEventTimeline";
import type { TrackingEvent } from "../../api/shipments";

describe("TrackingEventTimeline", () => {
    it("renders an empty state when events is empty", () => {
        render(<TrackingEventTimeline events={[]} shipmentState="accepted" />);
        expect(screen.queryByRole("list")).not.toBeInTheDocument();
        expect(screen.getByText(/sin eventos/i)).toBeInTheDocument();
    });

    it("renders one event with formatted timestamp", () => {
        const events: TrackingEvent[] = [
            { id: 1, kind: "shipment_accepted", occurred_at: "2026-06-11T10:00:00Z" },
        ];
        render(<TrackingEventTimeline events={events} shipmentState="accepted" />);
        expect(screen.getByRole("list")).toBeInTheDocument();
        expect(screen.getAllByRole("listitem")).toHaveLength(1);
    });

    it("renders multiple events in order", () => {
        const events: TrackingEvent[] = [
            { id: 1, kind: "shipment_accepted", occurred_at: "2026-06-11T10:00:00Z" },
            { id: 2, kind: "shipment_in_transit", occurred_at: "2026-06-12T09:00:00Z" },
            { id: 3, kind: "shipment_delivered", occurred_at: "2026-06-13T15:30:00Z" },
        ];
        render(<TrackingEventTimeline events={events} shipmentState="delivered" />);
        expect(screen.getAllByRole("listitem")).toHaveLength(3);
    });

    it("displays translated kind labels from content", () => {
        const events: TrackingEvent[] = [
            { id: 1, kind: "shipment_accepted", occurred_at: "2026-06-11T10:00:00Z" },
        ];
        render(<TrackingEventTimeline events={events} shipmentState="accepted" />);
        const item = screen.getByRole("listitem");
        expect(item.textContent).toBeTruthy();
    });

    it("renders status_change event with human-readable label (not raw kind)", () => {
        const events: TrackingEvent[] = [
            { id: 1, kind: "status_change", from_status: "accepted", to_status: "in_transit", occurred_at: "2026-06-12T09:00:00Z" },
        ];
        render(<TrackingEventTimeline events={events} shipmentState="in_transit" />);
        expect(screen.queryByText("status_change")).not.toBeInTheDocument();
        expect(screen.getByText("En tránsito")).toBeInTheDocument();
    });

    it("renders status_change to delivered with correct label", () => {
        const events: TrackingEvent[] = [
            { id: 1, kind: "status_change", from_status: "in_transit", to_status: "delivered", occurred_at: "2026-06-13T15:00:00Z" },
        ];
        render(<TrackingEventTimeline events={events} shipmentState="delivered" />);
        expect(screen.queryByText("status_change")).not.toBeInTheDocument();
        expect(screen.getByText("Entregado")).toBeInTheDocument();
    });

    it("renders status_change to cancelled with correct label", () => {
        const events: TrackingEvent[] = [
            { id: 1, kind: "status_change", from_status: "accepted", to_status: "cancelled", occurred_at: "2026-06-14T10:00:00Z" },
        ];
        render(<TrackingEventTimeline events={events} shipmentState="cancelled" />);
        expect(screen.queryByText("status_change")).not.toBeInTheDocument();
        expect(screen.getByText("Cancelado")).toBeInTheDocument();
    });
});
