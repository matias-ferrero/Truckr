import { beforeEach, describe, expect, it, vi } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { ShipperReviewForm } from "./ShipperReviewForm";
import * as reviewsApi from "../../api/reviews";
import { ApiError } from "../../api";
import type { Review } from "../../api/reviews";

vi.mock("../../api/reviews");

const api = vi.mocked(reviewsApi);

const createdReview: Review = {
    id: 8,
    rating: 5,
    body: "Entrega puntual.",
    authored_by: "shipper",
    created_at: "2026-05-29T10:00:00Z",
};

beforeEach(() => {
    vi.resetAllMocks();
});

describe("ShipperReviewForm", () => {
    it("renders the title, a 5-star radiogroup, a comment field and submit", () => {
        render(<ShipperReviewForm shipmentId={31} />);

        expect(screen.getByRole("heading", { name: "Dejar reseña" })).toBeInTheDocument();
        const group = screen.getByRole("radiogroup", { name: /puntuación/i });
        expect(group).toBeInTheDocument();
        expect(screen.getAllByRole("radio")).toHaveLength(5);
        expect(screen.getByLabelText(/comentario/i)).toBeInTheDocument();
        expect(screen.getByRole("button", { name: "Enviar reseña" })).toBeInTheDocument();
    });

    it("blocks submit and shows an error when no rating is selected", async () => {
        const user = userEvent.setup();
        render(<ShipperReviewForm shipmentId={31} />);

        await user.click(screen.getByRole("button", { name: "Enviar reseña" }));

        expect(screen.getByText(/elegí una puntuación/i)).toBeInTheDocument();
        expect(api.createShipmentReview).not.toHaveBeenCalled();
    });

    it("submits rating + comment and renders the created review (AC7)", async () => {
        const user = userEvent.setup();
        const onCreated = vi.fn();
        api.createShipmentReview.mockResolvedValue(createdReview);

        render(<ShipperReviewForm shipmentId={31} onCreated={onCreated} />);

        await user.click(screen.getByRole("radio", { name: "5 estrellas" }));
        await user.type(screen.getByLabelText(/comentario/i), "Entrega puntual.");
        await user.click(screen.getByRole("button", { name: "Enviar reseña" }));

        await waitFor(() => {
            expect(api.createShipmentReview).toHaveBeenCalledWith(31, {
                rating: 5,
                body: "Entrega puntual.",
            });
        });

        expect(await screen.findByText("¡Gracias por tu reseña!")).toBeInTheDocument();
        expect(screen.queryByRole("button", { name: "Enviar reseña" })).not.toBeInTheDocument();
        expect(onCreated).toHaveBeenCalledWith(createdReview);
    });

    it("sends body: null when no comment is typed", async () => {
        const user = userEvent.setup();
        api.createShipmentReview.mockResolvedValue({ ...createdReview, body: null });

        render(<ShipperReviewForm shipmentId={31} />);
        await user.click(screen.getByRole("radio", { name: "4 estrellas" }));
        await user.click(screen.getByRole("button", { name: "Enviar reseña" }));

        await waitFor(() => {
            expect(api.createShipmentReview).toHaveBeenCalledWith(31, { rating: 4, body: null });
        });
    });

    it("shows the already-reviewed message on a 409 conflict", async () => {
        const user = userEvent.setup();
        api.createShipmentReview.mockRejectedValue(new ApiError(409, "conflict", "conflict"));

        render(<ShipperReviewForm shipmentId={31} />);
        await user.click(screen.getByRole("radio", { name: "5 estrellas" }));
        await user.click(screen.getByRole("button", { name: "Enviar reseña" }));

        expect(await screen.findByRole("alert")).toHaveTextContent(/ya dejaste una reseña/i);
    });

    it("renders the read-only submitted state when an existing review is provided", () => {
        render(<ShipperReviewForm shipmentId={31} existingReview={createdReview} />);

        expect(screen.getByText("¡Gracias por tu reseña!")).toBeInTheDocument();
        expect(screen.getByText("Entrega puntual.")).toBeInTheDocument();
        expect(screen.queryByRole("button", { name: "Enviar reseña" })).not.toBeInTheDocument();
    });
});
