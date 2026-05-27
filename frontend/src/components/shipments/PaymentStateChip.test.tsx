import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { PaymentStateChip } from "./PaymentStateChip";

describe("PaymentStateChip", () => {
    it("renders 'Pendiente de pago' for pending state", () => {
        render(<PaymentStateChip paymentState="pending" />);
        expect(screen.getByText("Pendiente de pago")).toBeInTheDocument();
    });

    it("renders 'Pagado' for paid state", () => {
        render(<PaymentStateChip paymentState="paid" />);
        expect(screen.getByText("Pagado")).toBeInTheDocument();
    });

    it("applies the correct CSS modifier class", () => {
        const { container } = render(<PaymentStateChip paymentState="paid" />);
        expect(container.firstChild).toHaveClass("paymentStateChip--paid");
    });
});
