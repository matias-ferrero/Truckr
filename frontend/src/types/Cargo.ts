/* Frontend domain types for the Cargo publication funnel (US27 / REQ-BE-00032).
 *
 * These mirror the backend Alba serializers (`CargoResource`,
 * `CargoMatchResource`) field-for-field. Wire keys are snake_case — they are
 * the JSON contract, not internal camelCase identifiers, so they stay
 * snake_case here on purpose. First domain-type module in the FE; sets the
 * convention for future `types/` entries.
 */

/** Cargo publication lifecycle — no intermediate `offered` state (plan §2.2). */
export type CargoStatus = "open" | "accepted" | "cancelled";

/** A bid placed by a Carrier against a published Cargo (nested in CargoResource). */
export type CargoOfferStatus =
    | "pending"
    | "accepted"
    | "paid"
    | "expired"
    | "cancelled";

/** Carrier summary embedded inside a match / offer. */
export type CargoCarrierSummary = {
    id: number;
    display_name: string | null;
    rating_avg: string;
};

/** Vehicle summary embedded inside a match. */
export type CargoVehicleSummary = {
    id: number;
    make: string;
    model: string;
    plate: string;
    max_load_kg: string;
};

/**
 * A `TransportWindow` that can carry the cargo — zone-string matched
 * (plan §2.3). No `distance_km`: Haversine is deferred to the GMaps follow-up.
 */
export type CargoMatch = {
    id: number;
    origin_zone: string;
    destination_zone: string;
    price_per_km: string;
    max_km: number;
    available_from: string;
    available_to: string;
    vehicle: CargoVehicleSummary;
    carrier: CargoCarrierSummary;
};

/** An offer nested in a Cargo detail, with the window/carrier it targets. */
export type CargoOffer = {
    id: number;
    cargo_id: number;
    carrier_id: number;
    transport_window_id: number;
    amount_cents: number;
    currency: string;
    status: CargoOfferStatus;
    expires_at: string;
    created_at: string;
    updated_at: string;
    transport_window?: {
        id: number;
        origin_zone: string;
        destination_zone: string;
    };
};

/** A published Cargo — mirrors `CargoResource`. */
export type Cargo = {
    id: number;
    shipper_id: number;
    status: CargoStatus;
    cargo_description: string;
    pickup_address: string;
    delivery_address: string;
    pickup_zone: string;
    delivery_zone: string;
    pickup_window_start: string;
    pickup_window_end: string;
    weight_kg: string;
    volume_cm3: number | null;
    declared_value_cents: number;
    cancelled_at: string | null;
    created_at: string;
    updated_at: string;
    editable: boolean;
    pending_offers_count: number;
    cargo_offers: CargoOffer[];
    /** Present only on the `POST /api/cargos` create response. */
    matches?: CargoMatch[];
};

/** Wire format for the `POST` / `PATCH` request body. */
export type CargoDraft = {
    cargo_description: string;
    pickup_address: string;
    delivery_address: string;
    pickup_zone: string;
    delivery_zone: string;
    pickup_window_start: string;
    pickup_window_end: string;
    weight_kg: string;
    /** Optional — empty string means "omit" (volume is nullable). */
    volume_cm3: string;
    declared_value_cents: string;
};
