import { describe, expect, it } from "vitest";
import { isKnownNotificationType, notificationsRegistry } from "./notificationsRegistry";
import { landingContent } from "../../landingContent";

describe("notificationsRegistry", () => {
    it("maps every registered type to a view backed by a landingContent entry", () => {
        for (const type of Object.keys(notificationsRegistry) as Array<
            keyof typeof notificationsRegistry
        >) {
            const view = notificationsRegistry[type]({});
            expect(view.title).toBeTruthy();
            expect(view.body).toBeTruthy();
            // Copy must come from the i18n bundle, not be hardcoded in the renderer.
            expect(view.title).toBe(landingContent.notifications[type].title);
            expect(view.body).toBe(landingContent.notifications[type].body);
        }
    });

    it("recognises known types and rejects unknown ones", () => {
        expect(isKnownNotificationType("ping")).toBe(true);
        expect(isKnownNotificationType("cargo_offer_received")).toBe(true);
        expect(isKnownNotificationType("cargo_offer_accepted")).toBe(true);
        expect(isKnownNotificationType("cargo_offer_rejected")).toBe(true);
        expect(isKnownNotificationType("not_a_type")).toBe(false);
        expect(isKnownNotificationType(undefined)).toBe(false);
        expect(isKnownNotificationType(42)).toBe(false);
    });

    it("renders the cargo-offer resolution types from the i18n bundle (REQ-FE-00030)", () => {
        const accepted = notificationsRegistry.cargo_offer_accepted({
            cargo_offer_id: 123,
            cargo_id: 45,
            amount_cents: 1_500_000,
            currency: "ARS",
            shipment_id: 9,
        });
        expect(accepted.title).toBe(landingContent.notifications.cargo_offer_accepted.title);
        expect(accepted.body).toBe(landingContent.notifications.cargo_offer_accepted.body);

        const rejected = notificationsRegistry.cargo_offer_rejected({
            cargo_offer_id: 123,
            cargo_id: 45,
            amount_cents: 1_500_000,
            currency: "ARS",
        });
        expect(rejected.title).toBe(landingContent.notifications.cargo_offer_rejected.title);
        expect(rejected.body).toBe(landingContent.notifications.cargo_offer_rejected.body);
    });

    it("renders cargo_offer_received from the i18n bundle (REQ-FE-00031)", () => {
        const received = notificationsRegistry.cargo_offer_received({
            cargo_offer_id: 123,
            cargo_id: 45,
            transport_window_id: 9,
            amount_cents: 1_500_000,
            currency: "ARS",
        });
        expect(received.title).toBe(landingContent.notifications.cargo_offer_received.title);
        expect(received.body).toBe(landingContent.notifications.cargo_offer_received.body);

        // Harden: an empty / partial payload must not break the renderer.
        expect(() => notificationsRegistry.cargo_offer_received({})).not.toThrow();
    });

    it("does not break when an optional payload field (shipment_id) is missing", () => {
        // The accepted payload may omit shipment_id; the renderer must still
        // produce a valid view (harden — see REQ-FE-00030).
        expect(() =>
            notificationsRegistry.cargo_offer_accepted({
                cargo_offer_id: 123,
                cargo_id: 45,
                amount_cents: 1_500_000,
                currency: "ARS",
            }),
        ).not.toThrow();

        const view = notificationsRegistry.cargo_offer_accepted({});
        expect(view.title).toBeTruthy();
        expect(view.body).toBeTruthy();
    });
});
