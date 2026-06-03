/* Frontend domain types for the Cargo publication funnel (US27 / REQ-BE-00032,
 * REQ-BE-00039 / ADR-014).
 *
 * These mirror the backend Alba serializers (`CargoResource`,
 * `CargoMatchResource`) field-for-field. Wire keys are snake_case — they are
 * the JSON contract, not internal camelCase identifiers, so they stay
 * snake_case here on purpose.
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
 * A `TransportWindow` that can carry the cargo — address-driven bbox + dual
 * Haversine matched on the backend (REQ-BE-00039 / ADR-014). `*_lat` / `*_lng`
 * arrive as decimal strings (Rails `DECIMAL(9,6)` → JSON string) so the
 * client can run Haversine against the cargo's pickup point and display the
 * distance per match. Destination fields are null on "destino abierto" windows.
 */
export type CargoMatch = {
    id: number;
    origin_address: string;
    origin_locality: string;
    origin_admin_area: string;
    origin_lat: string;
    origin_lng: string;
    destination_address: string | null;
    destination_locality: string | null;
    destination_admin_area: string | null;
    destination_lat: string | null;
    destination_lng: string | null;
    price_per_km: string;
    max_km: number;
    pickup_radius_km: number;
    dropoff_radius_km: number | null;
    available_from: string;
    available_to: string;
    active: boolean;
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
        origin_locality: string;
        origin_admin_area: string;
        destination_locality: string | null;
        destination_admin_area: string | null;
        destination_lat: string | null;
        available_from: string;
        available_to: string;
    };
};

/** A published Cargo — mirrors `CargoResource`. */
export type Cargo = {
    id: number;
    shipper_id: number;
    status: CargoStatus;
    cargo_description: string;
    pickup_address: string;
    pickup_lat: string;
    pickup_lng: string;
    pickup_locality: string;
    pickup_admin_area: string;
    delivery_address: string;
    delivery_lat: string;
    delivery_lng: string;
    delivery_locality: string;
    delivery_admin_area: string;
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
    pickup_lat: number;
    pickup_lng: number;
    pickup_locality: string;
    pickup_admin_area: string;
    delivery_address: string;
    delivery_lat: number;
    delivery_lng: number;
    delivery_locality: string;
    delivery_admin_area: string;
    pickup_window_start: string;
    pickup_window_end: string;
    weight_kg: string;
    /** Optional — empty string means "omit" (volume is nullable). */
    volume_cm3: string;
    declared_value_cents: string;
};
