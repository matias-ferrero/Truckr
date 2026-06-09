import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { BoardCard } from "./BoardCard";
import type { BoardCard as BoardCardModel } from "./buildDashboardModel";

/* Focused coverage for BoardCard's badge-tone branch table and the
 * accessible-name fallback — branches the page-level tests don't all reach. */

function makeCard(overrides: Partial<BoardCardModel> = {}): BoardCardModel {
    return {
        key: "cargo-1",
        source: "cargo",
        refId: 1,
        origin: "CABA",
        destination: "Córdoba",
        priceCents: 5_000_000,
        currency: "ARS",
        column: "searching",
        badge: "no_offers",
        href: "/shipper/cargos/1",
        offersCount: 0,
        ...overrides,
    };
}

function renderCard(card: BoardCardModel) {
    return render(
        <MemoryRouter>
            <ul>
                <BoardCard card={card} />
            </ul>
        </MemoryRouter>,
    );
}

describe("BoardCard", () => {
    it.each([
        ["payment_pending", "is-urgent", "Pago pendiente"],
        ["has_offers", "is-sky", "1 oferta"],
        ["in_transit", "is-sky", "En camino"],
        ["delivered", "is-done", "Entregado"],
        ["to_review", "is-review", "Calificar"],
        ["no_offers", "is-neutral", "Sin ofertas"],
    ] as const)(
        "renders the %s badge with the %s tone class",
        (badge, toneClass, label) => {
            renderCard(makeCard({ badge, offersCount: badge === "has_offers" ? 1 : 0 }));
            const badgeEl = screen.getByText(label);
            expect(badgeEl).toHaveClass("dashBadge", toneClass);
        },
    );

    it("uses the 'Sin estado' status in the accessible name when there is no badge", () => {
        renderCard(makeCard({ badge: null }));
        const link = screen.getByRole("link", {
            name: /Estado: Sin estado\./,
        });
        expect(link).toHaveAttribute("href", "/shipper/cargos/1");
    });

    it("omits the price node when priceCents is null", () => {
        renderCard(makeCard({ priceCents: null }));
        expect(screen.queryByText(/\$/)).not.toBeInTheDocument();
    });
});
