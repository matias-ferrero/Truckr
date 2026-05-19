import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import Wizard, { type WizardStep } from "./Wizard";

const makeSteps = (count: number, canAdvance = true): WizardStep[] =>
    Array.from({ length: count }, (_, i) => ({
        label: `Paso ${i + 1}`,
        content: <div data-testid={`step-content-${i}`}>Contenido del paso {i + 1}</div>,
        canAdvance,
    }));

describe("Wizard", () => {
    const defaultProps = {
        onSubmit: vi.fn(),
        isSubmitting: false,
        nextLabel: "Siguiente",
        backLabel: "Atrás",
        submitLabel: "Enviar",
        submittingLabel: "Enviando…",
    };

    it("renders the first step label with aria-current=step", () => {
        render(<Wizard steps={makeSteps(3)} {...defaultProps} />);
        const firstStep = screen.getByText("Paso 1").closest("li");
        expect(firstStep).toHaveAttribute("aria-current", "step");
    });

    it("renders first step content", () => {
        render(<Wizard steps={makeSteps(3)} {...defaultProps} />);
        expect(screen.getByTestId("step-content-0")).toBeInTheDocument();
        expect(screen.queryByTestId("step-content-1")).not.toBeInTheDocument();
    });

    it("back button is disabled on the first step when no onCancel is provided", () => {
        render(<Wizard steps={makeSteps(3)} {...defaultProps} />);
        expect(screen.getByRole("button", { name: "Atrás" })).toBeDisabled();
    });

    it("back button on step 0 is enabled and calls onCancel when provided", async () => {
        const onCancel = vi.fn();
        const user = userEvent.setup();
        render(<Wizard steps={makeSteps(3)} {...defaultProps} onCancel={onCancel} />);
        const backBtn = screen.getByRole("button", { name: "Atrás" });
        expect(backBtn).not.toBeDisabled();
        await user.click(backBtn);
        expect(onCancel).toHaveBeenCalledOnce();
    });

    it("next button is disabled when canAdvance is false", () => {
        render(<Wizard steps={makeSteps(3, false)} {...defaultProps} />);
        expect(screen.getByRole("button", { name: "Siguiente" })).toBeDisabled();
    });

    it("next button is enabled when canAdvance is true", () => {
        render(<Wizard steps={makeSteps(3, true)} {...defaultProps} />);
        expect(screen.getByRole("button", { name: "Siguiente" })).not.toBeDisabled();
    });

    it("clicking next advances to the next step", async () => {
        const user = userEvent.setup();
        render(<Wizard steps={makeSteps(3)} {...defaultProps} />);

        await user.click(screen.getByRole("button", { name: "Siguiente" }));

        expect(screen.getByTestId("step-content-1")).toBeInTheDocument();
        expect(screen.queryByTestId("step-content-0")).not.toBeInTheDocument();

        const secondStep = screen.getByText("Paso 2").closest("li");
        expect(secondStep).toHaveAttribute("aria-current", "step");
    });

    it("clicking back returns to the previous step", async () => {
        const user = userEvent.setup();
        render(<Wizard steps={makeSteps(3)} {...defaultProps} />);

        await user.click(screen.getByRole("button", { name: "Siguiente" }));
        await user.click(screen.getByRole("button", { name: "Atrás" }));

        expect(screen.getByTestId("step-content-0")).toBeInTheDocument();
    });

    it("shows submit button on the last step instead of next", async () => {
        const user = userEvent.setup();
        render(<Wizard steps={makeSteps(2)} {...defaultProps} />);

        await user.click(screen.getByRole("button", { name: "Siguiente" }));

        expect(screen.queryByRole("button", { name: "Siguiente" })).not.toBeInTheDocument();
        expect(screen.getByRole("button", { name: "Enviar" })).toBeInTheDocument();
    });

    it("calls onSubmit when submit button is clicked", async () => {
        const onSubmit = vi.fn();
        const user = userEvent.setup();
        render(<Wizard steps={makeSteps(1)} {...defaultProps} onSubmit={onSubmit} />);

        await user.click(screen.getByRole("button", { name: "Enviar" }));
        expect(onSubmit).toHaveBeenCalledOnce();
    });

    it("shows submitting label and disables button while isSubmitting", () => {
        render(
            <Wizard steps={makeSteps(1)} {...defaultProps} isSubmitting={true} />,
        );
        const btn = screen.getByRole("button", { name: "Enviando…" });
        expect(btn).toBeDisabled();
    });

    it("marks earlier steps as done after advancing", async () => {
        const user = userEvent.setup();
        render(<Wizard steps={makeSteps(3)} {...defaultProps} />);

        await user.click(screen.getByRole("button", { name: "Siguiente" }));

        const firstStep = screen.getByText("Paso 1").closest("li");
        expect(firstStep?.className).toContain("wizardStepDone");
    });

    it("announces step 1 when navigating backward to step 0", async () => {
        const user = userEvent.setup();
        render(<Wizard steps={makeSteps(3)} {...defaultProps} onCancel={vi.fn()} />);

        await user.click(screen.getByRole("button", { name: "Siguiente" }));
        await user.click(screen.getByRole("button", { name: "Atrás" }));

        const announcer = document.querySelector('[role="status"]');
        expect(announcer?.textContent).toContain("Paso 1");
    });
});
