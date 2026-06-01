import { beforeEach, describe, expect, it, vi } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { CarrierReviewForm } from "./CarrierReviewForm";
import * as reviewsApi from "../../api/reviews";
import { ApiError } from "../../api";
import type { Review } from "../../api/reviews";

vi.mock("../../api/reviews");

const api = vi.mocked(reviewsApi);

const createdReview: Review = {
    id: 7,
    rating: 5,
    body: "Carga lista a horario.",
    authored_by: "carrier",
    created_at: "2026-05-29T10:00:00Z",
};

beforeEach(() => {
    vi.resetAllMocks();
});

describe("CarrierReviewForm", () => {
    it("renders the title, a 5-star radiogroup, a comment field and submit", () => {
        render(<CarrierReviewForm shipmentId={31} />);

        expect(screen.getByRole("heading", { name: "Reseñar al expedidor" })).toBeInTheDocument();
        const group = screen.getByRole("radiogroup", { name: /puntuación/i });
        expect(group).toBeInTheDocument();
        expect(screen.getAllByRole("radio")).toHaveLength(5);
        expect(screen.getByLabelText(/comentario/i)).toBeInTheDocument();
        expect(screen.getByRole("button", { name: "Enviar reseña" })).toBeInTheDocument();
    });

    it("blocks submit and shows an error when no rating is selected", async () => {
        const user = userEvent.setup();
        render(<CarrierReviewForm shipmentId={31} />);

        await user.click(screen.getByRole("button", { name: "Enviar reseña" }));

        expect(screen.getByText(/elegí una puntuación/i)).toBeInTheDocument();
        expect(api.createCarrierReview).not.toHaveBeenCalled();
    });

    it("submits rating + comment and renders the created review (AC7)", async () => {
        const user = userEvent.setup();
        const onCreated = vi.fn();
        api.createCarrierReview.mockResolvedValue(createdReview);

        render(<CarrierReviewForm shipmentId={31} onCreated={onCreated} />);

        await user.click(screen.getByRole("radio", { name: "5 estrellas" }));
        await user.type(screen.getByLabelText(/comentario/i), "Carga lista a horario.");
        await user.click(screen.getByRole("button", { name: "Enviar reseña" }));

        await waitFor(() => {
            expect(api.createCarrierReview).toHaveBeenCalledWith(31, {
                rating: 5,
                body: "Carga lista a horario.",
            });
        });

        expect(await screen.findByText("¡Gracias por tu reseña!")).toBeInTheDocument();
        expect(screen.queryByRole("button", { name: "Enviar reseña" })).not.toBeInTheDocument();
        expect(onCreated).toHaveBeenCalledWith(createdReview);
    });

    it("sends body: null when no comment is typed", async () => {
        const user = userEvent.setup();
        api.createCarrierReview.mockResolvedValue({ ...createdReview, body: null });

        render(<CarrierReviewForm shipmentId={31} />);
        await user.click(screen.getByRole("radio", { name: "4 estrellas" }));
        await user.click(screen.getByRole("button", { name: "Enviar reseña" }));

        await waitFor(() => {
            expect(api.createCarrierReview).toHaveBeenCalledWith(31, { rating: 4, body: null });
        });
    });

    it("shows the already-reviewed message on a 409 conflict", async () => {
        const user = userEvent.setup();
        api.createCarrierReview.mockRejectedValue(new ApiError(409, "conflict", "conflict"));

        render(<CarrierReviewForm shipmentId={31} />);
        await user.click(screen.getByRole("radio", { name: "5 estrellas" }));
        await user.click(screen.getByRole("button", { name: "Enviar reseña" }));

        expect(await screen.findByRole("alert")).toHaveTextContent(/ya dejaste una reseña/i);
    });

    it("renders the read-only submitted state when an existing review is provided", () => {
        render(<CarrierReviewForm shipmentId={31} existingReview={createdReview} />);

        expect(screen.getByText("¡Gracias por tu reseña!")).toBeInTheDocument();
        expect(screen.getByText("Carga lista a horario.")).toBeInTheDocument();
        expect(screen.queryByRole("button", { name: "Enviar reseña" })).not.toBeInTheDocument();
    });
});
