import { useState } from "react";
import { Navigate, useLocation, useNavigate, useParams } from "react-router-dom";
import { createCargoOffer, type CargoOffer, type CargoOfferDraft } from "../../api/quotes";
import type { CarrierDetail, TransportWindow } from "../../api/carriers";
import { ApiError } from "../../api";
import { offerContent } from "./offerContent";
import Wizard, { type WizardStep } from "../../components/Wizard";
import { FormField } from "../../components/ui/form-field";
import { Input } from "../../components/ui/input";
import { Select } from "../../components/ui/select";
import { Textarea } from "../../components/ui/textarea";
import { Button } from "../../components/ui/button";
import { Alert } from "../../components/ui/alert";

const t = offerContent;

const arsFormatter = new Intl.NumberFormat("es-AR", {
    style: "currency",
    currency: "ARS",
    maximumFractionDigits: 0,
});

// Navigation state set by CarrierDetail when launching the wizard.
type NavState = {
    carrier: CarrierDetail;
    window: TransportWindow;
};

type AddressDraft = {
    street: string;
    number: string;
    floor: string;
    postal_code: string;
    city: string;
    province: string;
};

type FormDraft = {
    pickup: AddressDraft;
    delivery: AddressDraft;
    cargo_description: string;
    weight_kg: string;
    volume_cm3: string;
    /** User enters pesos; converted × 100 to cents before POST. */
    declared_value_pesos: string;
    pickup_date: string;
    estimated_km: string;
};

const emptyAddress: AddressDraft = {
    street: "",
    number: "",
    floor: "",
    postal_code: "",
    city: "",
    province: "",
};

const emptyDraft: FormDraft = {
    pickup: { ...emptyAddress },
    delivery: { ...emptyAddress },
    cargo_description: "",
    weight_kg: "",
    volume_cm3: "",
    declared_value_pesos: "",
    pickup_date: "",
    estimated_km: "",
};

function addressComplete(addr: AddressDraft): boolean {
    return (
        addr.street.trim().length > 0 &&
        addr.number.trim().length > 0 &&
        addr.postal_code.trim().length > 0 &&
        addr.city.trim().length > 0 &&
        addr.province.length > 0
    );
}

function buildAddress(addr: AddressDraft): string {
    const streetLine = addr.floor.trim()
        ? `${addr.street} ${addr.number} ${addr.floor}`
        : `${addr.street} ${addr.number}`;
    return `${streetLine}, ${addr.postal_code} ${addr.city}, ${addr.province}`;
}

export default function CreateOfferPage() {
    const { id } = useParams<{ id: string }>();
    const carrierId = Number(id);
    const location = useLocation();
    const navigate = useNavigate();

    const navState = location.state as NavState | null;

    const [draft, setDraft] = useState<FormDraft>(emptyDraft);
    const [serverErrors, setServerErrors] = useState<Record<string, string[]>>({});
    const [confirmed, setConfirmed] = useState<CargoOffer | null>(null);
    const [submitError, setSubmitError] = useState<string | null>(null);
    const [isSubmitting, setIsSubmitting] = useState(false);

    // Without navigation state we can't show capacity hints or window details.
    if (!navState) {
        return <Navigate to={`/carriers/${carrierId}`} replace />;
    }

    const { carrier, window: selectedWindow } = navState;

    // Correlate window → vehicle for capacity hints.
    const vehicle = carrier.vehicles.find((v) => v.id === selectedWindow.vehicle_id) ?? null;

    function set(key: keyof Omit<FormDraft, "pickup" | "delivery">, value: string) {
        setDraft((prev) => ({ ...prev, [key]: value }));
        if (serverErrors[key]) {
            setServerErrors((prev) => {
                const next = { ...prev };
                delete next[key];
                return next;
            });
        }
    }

    function setAddr(which: "pickup" | "delivery", key: keyof AddressDraft, value: string) {
        setDraft((prev) => ({ ...prev, [which]: { ...prev[which], [key]: value } }));
        const errKey = which === "pickup" ? "pickup_address" : "delivery_address";
        if (serverErrors[errKey]) {
            setServerErrors((prev) => {
                const next = { ...prev };
                delete next[errKey];
                return next;
            });
        }
    }

    const maxWeight = vehicle?.max_load_kg ?? null;
    const maxVolume = vehicle?.volume_cm3 ?? null;

    // Derived booleans for step canAdvance.
    const parsedWeight = parseFloat(draft.weight_kg);
    const parsedVolume = parseInt(draft.volume_cm3, 10);
    const weightExceedsCapacity =
        maxWeight !== null && parsedWeight > 0 && parsedWeight > parseFloat(maxWeight);
    const volumeExceedsCapacity =
        maxVolume !== null && parsedVolume > 0 && parsedVolume > maxVolume;
    const weightOk = parsedWeight > 0 && !weightExceedsCapacity;
    const volumeOk = parsedVolume > 0 && !volumeExceedsCapacity;
    const valueOk =
        draft.declared_value_pesos !== "" && parseFloat(draft.declared_value_pesos) >= 0;
    const estimatedKm = parseFloat(draft.estimated_km);
    const pricePerKm = parseFloat(selectedWindow.price_per_km);
    const estimatedCostARS = estimatedKm > 0 && pricePerKm > 0 ? estimatedKm * pricePerKm : null;

    async function handleSubmit() {
        setIsSubmitting(true);
        setSubmitError(null);
        try {
            const payload: CargoOfferDraft = {
                transport_window_id: selectedWindow.id,
                pickup_address: buildAddress(draft.pickup),
                delivery_address: buildAddress(draft.delivery),
                pickup_date: draft.pickup_date,
                cargo_description: draft.cargo_description.trim(),
                weight_kg: draft.weight_kg,
                volume_cm3: draft.volume_cm3,
                declared_value_cents: Math.round(
                    parseFloat(draft.declared_value_pesos) * 100,
                ).toString(),
                estimated_km: draft.estimated_km,
            };
            const cargoOffer = await createCargoOffer(payload);
            setConfirmed(cargoOffer);
        } catch (err) {
            if (err instanceof ApiError && err.details) {
                setServerErrors(err.details as Record<string, string[]>);
            }
            setSubmitError(t.errors.saveError);
        } finally {
            setIsSubmitting(false);
        }
    }

    // Confirmation screen — shown after successful submit.
    if (confirmed) {
        return (
            <main className="page publicMain" id="main">
                <div className="container">
                    <section
                        className="confirmationPanel"
                        role="status"
                        data-testid="confirmation-screen"
                    >
                        <h1 className="sectionTitle">{t.confirmation.title}</h1>
                        <p>{t.confirmation.lead}</p>
                        <p className="confirmationRef">{t.confirmation.quoteRef(confirmed.id)}</p>
                        <p className="confirmationStatus">{t.confirmation.status}</p>
                        <Button onClick={() => navigate("/")}>{t.confirmation.backToHome}</Button>
                    </section>
                </div>
            </main>
        );
    }

    const dateMin = selectedWindow.available_from.slice(0, 10);
    const dateMax = selectedWindow.available_to.slice(0, 10);

    // steps is intentionally NOT wrapped in useMemo: every dependency that
    // affects canAdvance or field values (draft, serverErrors, derived booleans)
    // changes on every keystroke anyway, so memoization would not skip any
    // re-renders and would only add bookkeeping overhead.
    const steps: WizardStep[] = [
        {
            label: t.stepLabels[0],
            canAdvance: addressComplete(draft.pickup) && addressComplete(draft.delivery),
            content: (
                <div className="wizardFieldset">
                    <h2 className="wizardLegend">{t.steps.addresses.heading}</h2>

                    <div className="addressGroup" role="group" aria-labelledby="pickup-group-title">
                        <p id="pickup-group-title" className="addressGroupTitle">
                            {t.steps.addresses.pickupGroup}
                        </p>
                        <div className="addressInlineGrid">
                            <FormField
                                id="pickup_street"
                                label={t.steps.addresses.street}
                                error={serverErrors["pickup_address"]?.[0]}
                                required
                            >
                                <Input
                                    id="pickup_street"
                                    value={draft.pickup.street}
                                    onChange={(e) => setAddr("pickup", "street", e.target.value)}
                                    autoComplete="shipping address-line1"
                                    autoFocus
                                />
                            </FormField>
                            <FormField id="pickup_number" label={t.steps.addresses.streetNumber} required>
                                <Input
                                    id="pickup_number"
                                    value={draft.pickup.number}
                                    onChange={(e) => setAddr("pickup", "number", e.target.value)}
                                />
                            </FormField>
                        </div>
                        <FormField id="pickup_floor" label={t.steps.addresses.floor}>
                            <Input
                                id="pickup_floor"
                                value={draft.pickup.floor}
                                onChange={(e) => setAddr("pickup", "floor", e.target.value)}
                                placeholder={t.steps.addresses.floorPlaceholder}
                            />
                        </FormField>
                        <div className="addressInlineGrid">
                            <FormField id="pickup_postal_code" label={t.steps.addresses.postalCode} required>
                                <Input
                                    id="pickup_postal_code"
                                    value={draft.pickup.postal_code}
                                    onChange={(e) =>
                                        setAddr("pickup", "postal_code", e.target.value)}
                                    autoComplete="shipping postal-code"
                                />
                            </FormField>
                            <FormField id="pickup_city" label={t.steps.addresses.city} required>
                                <Input
                                    id="pickup_city"
                                    value={draft.pickup.city}
                                    onChange={(e) => setAddr("pickup", "city", e.target.value)}
                                    autoComplete="shipping address-level2"
                                />
                            </FormField>
                        </div>
                        <FormField id="pickup_province" label={t.steps.addresses.province} required>
                            <Select
                                id="pickup_province"
                                value={draft.pickup.province}
                                onChange={(e) => setAddr("pickup", "province", e.target.value)}
                                autoComplete="shipping address-level1"
                            >
                                <option value="">{t.steps.addresses.provinceDefault}</option>
                                {t.steps.addresses.provinces.map((p) => (
                                    <option key={p} value={p}>{p}</option>
                                ))}
                            </Select>
                        </FormField>
                    </div>

                    <div
                        className="addressGroup"
                        role="group"
                        aria-labelledby="delivery-group-title"
                    >
                        <p id="delivery-group-title" className="addressGroupTitle">
                            {t.steps.addresses.deliveryGroup}
                        </p>
                        <div className="addressInlineGrid">
                            <FormField
                                id="delivery_street"
                                label={t.steps.addresses.street}
                                error={serverErrors["delivery_address"]?.[0]}
                                required
                            >
                                <Input
                                    id="delivery_street"
                                    value={draft.delivery.street}
                                    onChange={(e) =>
                                        setAddr("delivery", "street", e.target.value)}
                                    autoComplete="billing address-line1"
                                />
                            </FormField>
                            <FormField
                                id="delivery_number"
                                label={t.steps.addresses.streetNumber}
                                required
                            >
                                <Input
                                    id="delivery_number"
                                    value={draft.delivery.number}
                                    onChange={(e) =>
                                        setAddr("delivery", "number", e.target.value)}
                                />
                            </FormField>
                        </div>
                        <FormField id="delivery_floor" label={t.steps.addresses.floor}>
                            <Input
                                id="delivery_floor"
                                value={draft.delivery.floor}
                                onChange={(e) => setAddr("delivery", "floor", e.target.value)}
                                placeholder={t.steps.addresses.floorPlaceholder}
                            />
                        </FormField>
                        <div className="addressInlineGrid">
                            <FormField
                                id="delivery_postal_code"
                                label={t.steps.addresses.postalCode}
                                required
                            >
                                <Input
                                    id="delivery_postal_code"
                                    value={draft.delivery.postal_code}
                                    onChange={(e) =>
                                        setAddr("delivery", "postal_code", e.target.value)}
                                    autoComplete="billing postal-code"
                                />
                            </FormField>
                            <FormField id="delivery_city" label={t.steps.addresses.city} required>
                                <Input
                                    id="delivery_city"
                                    value={draft.delivery.city}
                                    onChange={(e) =>
                                        setAddr("delivery", "city", e.target.value)}
                                    autoComplete="billing address-level2"
                                />
                            </FormField>
                        </div>
                        <FormField id="delivery_province" label={t.steps.addresses.province} required>
                            <Select
                                id="delivery_province"
                                value={draft.delivery.province}
                                onChange={(e) =>
                                    setAddr("delivery", "province", e.target.value)}
                                autoComplete="billing address-level1"
                            >
                                <option value="">{t.steps.addresses.provinceDefault}</option>
                                {t.steps.addresses.provinces.map((p) => (
                                    <option key={p} value={p}>{p}</option>
                                ))}
                            </Select>
                        </FormField>
                    </div>
                </div>
            ),
        },
        {
            label: t.stepLabels[1],
            canAdvance:
                draft.cargo_description.trim().length > 0 && weightOk && volumeOk && valueOk,
            content: (
                <div className="wizardFieldset">
                    <h2 className="wizardLegend">{t.steps.cargo.heading}</h2>
                    <FormField
                        id="cargo_description"
                        label={t.steps.cargo.cargoDescription}
                        error={serverErrors["cargo_description"]?.[0]}
                        required
                    >
                        <Textarea
                            id="cargo_description"
                            value={draft.cargo_description}
                            onChange={(e) => set("cargo_description", e.target.value)}
                            rows={3}
                        />
                    </FormField>
                    <div className="cargoMetrics">
                        <FormField
                            id="weight_kg"
                            label={t.steps.cargo.weightKg}
                            required
                            help={maxWeight && !weightExceedsCapacity
                                ? t.steps.cargo.weightHint(maxWeight)
                                : undefined}
                            error={weightExceedsCapacity && maxWeight
                                ? t.steps.cargo.weightExceeded(maxWeight)
                                : serverErrors["weight_kg"]?.[0]}
                        >
                            <Input
                                id="weight_kg"
                                type="number"
                                min="0.1"
                                step="0.1"
                                value={draft.weight_kg}
                                onChange={(e) => set("weight_kg", e.target.value)}
                            />
                        </FormField>
                        <FormField
                            id="volume_cm3"
                            label={t.steps.cargo.volumeCm3}
                            required
                            help={
                                volumeExceedsCapacity ? undefined
                                : maxVolume != null
                                ? t.steps.cargo.volumeHint(maxVolume)
                                : t.steps.cargo.volumeNoLimit
                            }
                            error={volumeExceedsCapacity && maxVolume != null
                                ? t.steps.cargo.volumeExceeded(maxVolume)
                                : serverErrors["volume_cm3"]?.[0]}
                        >
                            <Input
                                id="volume_cm3"
                                type="number"
                                min="1"
                                step="1"
                                value={draft.volume_cm3}
                                onChange={(e) => set("volume_cm3", e.target.value)}
                            />
                        </FormField>
                        <FormField
                            id="declared_value_pesos"
                            label={t.steps.cargo.declaredValue}
                            error={serverErrors["declared_value_cents"]?.[0]}
                            required
                        >
                            <Input
                                id="declared_value_pesos"
                                type="number"
                                min="0"
                                step="1"
                                value={draft.declared_value_pesos}
                                onChange={(e) => set("declared_value_pesos", e.target.value)}
                            />
                        </FormField>
                    </div>
                </div>
            ),
        },
        {
            label: t.stepLabels[2],
            canAdvance: draft.pickup_date.length > 0 && estimatedKm > 0,
            content: (
                <div className="wizardFieldset">
                    <h2 className="wizardLegend">{t.steps.review.heading}</h2>
                    <section className="windowSummaryCard" aria-label={t.steps.review.windowInfo}>
                        <p className="windowZone">
                            {t.steps.review.windowZone(
                                selectedWindow.origin_zone,
                                selectedWindow.destination_zone,
                            )}
                        </p>
                        <p className="windowRate">
                            {t.steps.review.windowRate(selectedWindow.price_per_km)}
                        </p>
                    </section>
                    <FormField
                        id="pickup_date"
                        label={t.steps.review.pickupDate}
                        help={t.steps.review.pickupDateHint(dateMin, dateMax)}
                        error={serverErrors["pickup_date"]?.[0]}
                        required
                    >
                        <Input
                            id="pickup_date"
                            type="date"
                            min={dateMin}
                            max={dateMax}
                            value={draft.pickup_date}
                            onChange={(e) => set("pickup_date", e.target.value)}
                        />
                    </FormField>
                    <FormField
                        id="estimated_km"
                        label={t.steps.review.estimatedKm}
                        error={serverErrors["estimated_km"]?.[0]}
                        required
                    >
                        <Input
                            id="estimated_km"
                            type="number"
                            min="1"
                            step="1"
                            value={draft.estimated_km}
                            onChange={(e) => set("estimated_km", e.target.value)}
                        />
                    </FormField>
                    <div className="costEstimate" aria-live="polite" data-testid="cost-estimate">
                        <span>{t.steps.review.estimatedCost}: </span>
                        <strong>
                            {estimatedCostARS != null
                                ? arsFormatter.format(estimatedCostARS)
                                : t.steps.review.noEstimate}
                        </strong>
                    </div>
                </div>
            ),
        },
    ];

    return (
        <main className="page publicMain" id="main">
            <div className="container">
                <div className="wizardPage">
                    <h1 className="sectionTitle">{t.title}</h1>
                    {submitError && (
                        <Alert tone="error" role="alert">
                            {submitError}
                        </Alert>
                    )}
                    <Wizard
                        steps={steps}
                        onSubmit={handleSubmit}
                        isSubmitting={isSubmitting}
                        nextLabel={t.nav.next}
                        backLabel={t.nav.back}
                        submitLabel={t.nav.submit}
                        submittingLabel={t.nav.submitting}
                        onCancel={() => navigate(`/carriers/${carrierId}`)}
                        stepAnnouncementTemplate={t.stepAnnouncement}
                    />
                </div>
            </div>
        </main>
    );
}
