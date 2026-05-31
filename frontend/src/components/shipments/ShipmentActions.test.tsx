import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { ShipmentActions } from "./ShipmentActions";

describe("ShipmentActions", () => {
    it("renders nothing when available_actions is empty", () => {
        const { container } = render(
            <ShipmentActions
                available_actions={[]}
                payLabel="pay"
                isActing={false}
                actionError={null}
                onAction={vi.fn()}
            />,
        );
        expect(container.firstChild).toBeNull();
    });

    it("renders Pagar button for pay action", () => {
        render(
            <ShipmentActions
                available_actions={["pay"]}
                payLabel="pay"
                isActing={false}
                actionError={null}
                onAction={vi.fn()}
            />,
        );
        expect(screen.getByRole("button", { name: /pagar/i })).toBeInTheDocument();
    });

    it("renders Reintentar pago label when payLabel=retry_payment", () => {
        render(
            <ShipmentActions
                available_actions={["pay"]}
                payLabel="retry_payment"
                isActing={false}
                actionError={null}
                onAction={vi.fn()}
            />,
        );
        expect(screen.getByRole("button", { name: /reintentar pago/i })).toBeInTheDocument();
    });

    it("shows confirmation modal for pay before calling onAction", async () => {
        const user = userEvent.setup();
        const onAction = vi.fn();
        render(
            <ShipmentActions
                available_actions={["pay"]}
                payLabel="pay"
                isActing={false}
                actionError={null}
                onAction={onAction}
            />,
        );
        await user.click(screen.getByRole("button", { name: /pagar/i }));
        expect(onAction).not.toHaveBeenCalled();
        expect(screen.getByRole("dialog")).toBeInTheDocument();
    });

    it("calls onAction after confirming pay modal", async () => {
        const user = userEvent.setup();
        const onAction = vi.fn();
        render(
            <ShipmentActions
                available_actions={["pay"]}
                payLabel="pay"
                isActing={false}
                actionError={null}
                onAction={onAction}
            />,
        );
        await user.click(screen.getByRole("button", { name: /pagar/i }));
        await user.click(screen.getByRole("button", { name: /confirmar/i }));
        expect(onAction).toHaveBeenCalledWith("pay");
    });

    it("shows confirmation modal for start_transit before calling onAction", async () => {
        const user = userEvent.setup();
        const onAction = vi.fn();
        render(
            <ShipmentActions
                available_actions={["start_transit"]}
                payLabel="pay"
                isActing={false}
                actionError={null}
                onAction={onAction}
            />,
        );
        await user.click(screen.getByRole("button", { name: /iniciar transporte/i }));
        expect(onAction).not.toHaveBeenCalled();
        expect(screen.getByRole("dialog")).toBeInTheDocument();
    });

    it("calls onAction after confirming start_transit modal", async () => {
        const user = userEvent.setup();
        const onAction = vi.fn();
        render(
            <ShipmentActions
                available_actions={["start_transit"]}
                payLabel="pay"
                isActing={false}
                actionError={null}
                onAction={onAction}
            />,
        );
        await user.click(screen.getByRole("button", { name: /iniciar transporte/i }));
        await user.click(screen.getByRole("button", { name: /confirmar/i }));
        expect(onAction).toHaveBeenCalledWith("start_transit");
    });

    it("dismisses modal on cancel without calling onAction", async () => {
        const user = userEvent.setup();
        const onAction = vi.fn();
        render(
            <ShipmentActions
                available_actions={["deliver"]}
                payLabel="pay"
                isActing={false}
                actionError={null}
                onAction={onAction}
            />,
        );
        await user.click(screen.getByRole("button", { name: /confirmar entrega/i }));
        await user.click(screen.getByRole("button", { name: /cancelar/i }));
        expect(onAction).not.toHaveBeenCalled();
        await waitFor(() => expect(screen.queryByRole("dialog")).not.toBeInTheDocument());
    });

    it("disables all buttons while isActing=true", () => {
        render(
            <ShipmentActions
                available_actions={["pay", "start_transit"]}
                payLabel="pay"
                isActing={true}
                actionError={null}
                onAction={vi.fn()}
            />,
        );
        screen.getAllByRole("button").forEach((btn) => {
            expect(btn).toBeDisabled();
        });
    });

    it("shows actionError when present", () => {
        render(
            <ShipmentActions
                available_actions={["deliver"]}
                payLabel="pay"
                isActing={false}
                actionError="No pudimos completar la acción. Intentá de nuevo."
                onAction={vi.fn()}
            />,
        );
        expect(screen.getByRole("alert")).toBeInTheDocument();
        expect(screen.getByText(/no pudimos completar/i)).toBeInTheDocument();
    });
});
