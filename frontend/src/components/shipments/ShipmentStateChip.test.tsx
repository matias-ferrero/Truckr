import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { ShipmentStateChip } from "./ShipmentStateChip";

describe("ShipmentStateChip", () => {
    it("renders 'Aceptado' for accepted state", () => {
        render(<ShipmentStateChip state="accepted" />);
        expect(screen.getByText("Aceptado")).toBeInTheDocument();
    });

    it("renders 'En tránsito' for in_transit state", () => {
        render(<ShipmentStateChip state="in_transit" />);
        expect(screen.getByText("En tránsito")).toBeInTheDocument();
    });

    it("renders 'Entregado' for delivered state", () => {
        render(<ShipmentStateChip state="delivered" />);
        expect(screen.getByText("Entregado")).toBeInTheDocument();
    });

    it("renders 'Cancelado' for cancelled state", () => {
        render(<ShipmentStateChip state="cancelled" />);
        expect(screen.getByText("Cancelado")).toBeInTheDocument();
    });

    it("applies the correct CSS modifier class", () => {
        const { container } = render(<ShipmentStateChip state="in_transit" />);
        expect(container.firstChild).toHaveClass("shipmentStateChip--in_transit");
    });
});
