import { beforeEach, describe, expect, it, vi } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import ShipperDetail from "./ShipperDetail";
import { ApiError } from "../../api";
import { AuthContext, type AuthState } from "../../auth/AuthContext";
import * as shippersApi from "../../api/shippers";
import type { ReviewListResult, ShipperDetail as ShipperDetailDto } from "../../api/shippers";
import type { Review } from "../../api/reviews";

vi.mock("../../api/shippers", async (orig) => {
    const actual = await orig<typeof shippersApi>();
    return {
        ...actual,
        getShipper: vi.fn(),
        listShipperReviews: vi.fn(),
    };
});

function renderAt(url: string) {
    return render(
        <MemoryRouter initialEntries={[url]}>
            <Routes>
                <Route path="/shippers/:id" element={<ShipperDetail />} />
            </Routes>
        </MemoryRouter>,
    );
}

// Renders with an authenticated shipper viewer so owner-only UI (the edit
// button) can be exercised. ShipperDetail reads AuthContext directly.
function renderAsShipper(url: string, myShipperId: number) {
    const value = {
        me: {
            id: 1,
            email: "me@example.com",
            full_name: "Me",
            roles: ["shipper"],
            carrier: null,
            shipper: { id: myShipperId },
        },
        loading: false,
    } as unknown as AuthState;
    return render(
        <AuthContext.Provider value={value}>
            <MemoryRouter initialEntries={[url]}>
                <Routes>
                    <Route path="/shippers/:id" element={<ShipperDetail />} />
                    <Route path="/profile" element={<div>profile-screen</div>} />
                </Routes>
            </MemoryRouter>
        </AuthContext.Provider>,
    );
}

function fakeShipper(over: Partial<ShipperDetailDto> = {}): ShipperDetailDto {
    return {
        id: 4,
        company_name: "Expede SA",
        tax_id: "30-1234-5",
        billing_address: "Av. Siempreviva 742",
        rating_avg: "4.3",
        reviews_count: 3,
        created_at: "",
        updated_at: "",
        ...over,
    };
}

function review(over: Partial<Review> = {}): Review {
    return {
        id: 1,
        rating: 5,
        body: "Carga lista a horario, comunicación impecable.",
        authored_by: "carrier",
        created_at: "2026-06-01T10:00:00Z",
        ...over,
    };
}

function reviewPage(reviews: Review[], over: Partial<ReviewListResult["meta"]> = {}): ReviewListResult {
    return {
        reviews,
        meta: { total: reviews.length, page: 1, perPage: 10, totalPages: 1, ...over },
    };
}

describe("ShipperDetail", () => {
    beforeEach(() => {
        vi.resetAllMocks();
    });

    it("renders the hero with average rating and reviews count (AC2)", async () => {
        vi.mocked(shippersApi.getShipper).mockResolvedValueOnce(fakeShipper());
        vi.mocked(shippersApi.listShipperReviews).mockResolvedValueOnce(
            reviewPage([review(), review({ id: 2, rating: 4, body: null })]),
        );
        renderAt("/shippers/4");

        expect(await screen.findByRole("heading", { name: /expede sa/i })).toBeInTheDocument();
        expect(screen.getByText("4,3/5")).toBeInTheDocument();
        expect(screen.getByText("3 reseñas")).toBeInTheDocument();
    });

    it("renders individual review cards (rating, date, text) (AC5)", async () => {
        vi.mocked(shippersApi.getShipper).mockResolvedValueOnce(fakeShipper());
        vi.mocked(shippersApi.listShipperReviews).mockResolvedValueOnce(
            reviewPage([review()]),
        );
        renderAt("/shippers/4");

        expect(await screen.findByText(/carga lista a horario/i)).toBeInTheDocument();
        expect(screen.getByText("5/5")).toBeInTheDocument();
    });

    it("shows empty stars + 'Sin reseñas todavía' in the hero when there are no reviews", async () => {
        vi.mocked(shippersApi.getShipper).mockResolvedValueOnce(
            fakeShipper({ rating_avg: null, reviews_count: 0 }),
        );
        vi.mocked(shippersApi.listShipperReviews).mockResolvedValueOnce(reviewPage([]));
        renderAt("/shippers/4");

        // Hero shows the carrier-style empty label next to the (empty) stars.
        expect(await screen.findByText(/sin reseñas todavía/i)).toBeInTheDocument();
        // The reviews section settles its own async load; await it too.
        expect(await screen.findByText(/todavía no tiene reseñas/i)).toBeInTheDocument();
    });

    it("loads the next page when 'Ver más' is clicked", async () => {
        vi.mocked(shippersApi.getShipper).mockResolvedValueOnce(
            fakeShipper({ reviews_count: 12 }),
        );
        vi.mocked(shippersApi.listShipperReviews)
            .mockResolvedValueOnce(reviewPage([review({ id: 1 })], { total: 12, page: 1, totalPages: 2 }))
            .mockResolvedValueOnce(reviewPage([review({ id: 2, body: "Segunda página." })], {
                total: 12,
                page: 2,
                totalPages: 2,
            }));
        const user = userEvent.setup();
        renderAt("/shippers/4");

        const more = await screen.findByRole("button", { name: /ver más reseñas/i });
        await user.click(more);

        await waitFor(() => expect(screen.getByText(/segunda página/i)).toBeInTheDocument());
        expect(shippersApi.listShipperReviews).toHaveBeenCalledWith(4, 2);
    });

    it("shows a not-found state when the profile returns 404", async () => {
        vi.mocked(shippersApi.getShipper).mockRejectedValueOnce(
            new ApiError(404, "Recurso no encontrado", "not_found"),
        );
        renderAt("/shippers/999");

        expect(await screen.findByText(/expedidor no encontrado/i)).toBeInTheDocument();
    });

    it("shows the 'editar mi perfil' button to the owner viewer", async () => {
        vi.mocked(shippersApi.getShipper).mockResolvedValueOnce(fakeShipper({ id: 4 }));
        vi.mocked(shippersApi.listShipperReviews).mockResolvedValueOnce(reviewPage([]));
        renderAsShipper("/shippers/4", 4);

        const edit = await screen.findByRole("link", { name: /editar mi perfil/i });
        expect(edit).toHaveAttribute("href", "/profile");
    });

    it("hides the edit button when the viewer is not the profile owner", async () => {
        vi.mocked(shippersApi.getShipper).mockResolvedValueOnce(fakeShipper({ id: 4 }));
        vi.mocked(shippersApi.listShipperReviews).mockResolvedValueOnce(reviewPage([]));
        renderAsShipper("/shippers/4", 99);

        await screen.findByRole("heading", { name: /expede sa/i });
        expect(screen.queryByRole("link", { name: /editar mi perfil/i })).toBeNull();
    });
});
