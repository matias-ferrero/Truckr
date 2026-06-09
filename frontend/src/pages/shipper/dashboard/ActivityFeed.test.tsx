import { describe, expect, it } from "vitest";
import { render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter } from "react-router-dom";
import { ActivityFeed, FEED_PAGE_SIZE } from "./ActivityFeed";
import type { ActivityItem } from "./buildActivityFeed";

function makeItem(i: number, overrides: Partial<ActivityItem> = {}): ActivityItem {
    return {
        key: `event-${i}`,
        at: `2026-06-${String((i % 27) + 1).padStart(2, "0")}T00:00:00Z`,
        type: "note",
        refId: i,
        href: `/shipper/shipments/${i}`,
        origin: "Rosario",
        destination: "Mendoza",
        amountCents: null,
        currency: null,
        ...overrides,
    };
}

function renderFeed(items: ActivityItem[]) {
    return render(
        <MemoryRouter>
            <ActivityFeed items={items} />
        </MemoryRouter>,
    );
}

describe("ActivityFeed", () => {
    it("renders the empty state without a pager", () => {
        renderFeed([]);
        expect(screen.getByText("Sin actividad reciente")).toBeInTheDocument();
        expect(screen.queryByRole("navigation")).not.toBeInTheDocument();
    });

    it("renders all items without a pager when they fit on one page", () => {
        renderFeed([makeItem(1), makeItem(2)]);
        expect(screen.getAllByRole("listitem")).toHaveLength(2);
        expect(screen.queryByRole("navigation")).not.toBeInTheDocument();
    });

    it("shows the route and timestamp detail on a row", () => {
        renderFeed([makeItem(1, { origin: "Córdoba", destination: "Salta" })]);
        const row = screen.getByRole("listitem");
        expect(row).toHaveTextContent("Córdoba");
        expect(row).toHaveTextContent("Salta");
    });

    it("omits the route line when the item has no resolved route", () => {
        renderFeed([makeItem(1, { origin: null, destination: null })]);
        expect(screen.getByRole("listitem")).not.toHaveTextContent("Rosario");
    });

    it("shows the formatted amount when present", () => {
        renderFeed([
            makeItem(1, { type: "payment_escrowed", amountCents: 5_500_000, currency: "ARS" }),
        ]);
        // es-AR currency formatting (NBSP between symbol and digits tolerated).
        expect(screen.getByText(/\$\s?55\.000/)).toBeInTheDocument();
    });

    it("paginates: shows one page, navigates forward and back, and disables at edges", async () => {
        const user = userEvent.setup();
        const total = FEED_PAGE_SIZE * 2 + 3; // 3 pages: 6 + 6 + 3
        renderFeed(Array.from({ length: total }, (_, i) => makeItem(i + 1)));

        expect(screen.getAllByRole("listitem")).toHaveLength(FEED_PAGE_SIZE);
        expect(screen.getByText(`1–6 de ${total}`)).toBeInTheDocument();

        const prev = screen.getByRole("button", { name: "Anterior" });
        const next = screen.getByRole("button", { name: "Siguiente" });
        expect(prev).toBeDisabled();

        await user.click(next);
        expect(screen.getByText(`7–12 de ${total}`)).toBeInTheDocument();
        expect(prev).toBeEnabled();

        await user.click(next);
        // Last page: only the remaining 3 items, "next" disabled.
        expect(screen.getByText(`13–15 de ${total}`)).toBeInTheDocument();
        expect(screen.getAllByRole("listitem")).toHaveLength(3);
        expect(next).toBeDisabled();

        await user.click(prev);
        expect(screen.getByText(`7–12 de ${total}`)).toBeInTheDocument();
    });
});
