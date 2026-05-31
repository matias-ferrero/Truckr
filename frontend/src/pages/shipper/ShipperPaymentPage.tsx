import { useEffect, useRef, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { ApiError } from "../../api";
import { createShipmentPayment, getShipmentDetail } from "../../api/shipments";
import type { ShipmentDetail } from "../../api/shipments";
import { Button } from "../../components/ui/button";
import ProvinceSelect from "../../components/ProvinceSelect";
import { paymentContent as t } from "./paymentContent";
import "../../styles/shipments.css";

type FieldKey =
    | "cardNumber"
    | "expiry"
    | "cvv"
    | "holder"
    | "street"
    | "city"
    | "province"
    | "postalCode";

type FormState = Record<FieldKey, string>;
type FieldErrors = Partial<Record<FieldKey, string>>;
type TouchedMap = Partial<Record<FieldKey, true>>;

const EMPTY_FORM: FormState = {
    cardNumber: "",
    expiry: "",
    cvv: "",
    holder: "",
    street: "",
    city: "",
    province: "",
    postalCode: "",
};

// Field order drives "focus first invalid" behavior on submit.
const FIELD_ORDER: FieldKey[] = [
    "cardNumber",
    "expiry",
    "cvv",
    "holder",
    "street",
    "city",
    "province",
    "postalCode",
];

const INPUT_ID: Record<FieldKey, string> = {
    cardNumber: "payCardNumber",
    expiry:     "payExpiry",
    cvv:        "payCvv",
    holder:     "payHolder",
    street:     "payStreet",
    city:       "payCity",
    province:   "payProvince",
    postalCode: "payPostalCode",
};

// Luhn check on a digits-only string.
function luhnValid(digits: string): boolean {
    if (digits.length === 0) return false;
    let sum = 0;
    const parity = digits.length % 2;
    for (let i = 0; i < digits.length; i++) {
        let d = Number(digits[i]);
        if (i % 2 === parity) d *= 2;
        if (d > 9) d -= 9;
        sum += d;
    }
    return sum % 10 === 0;
}

function formatCardNumber(value: string): string {
    const digits = value.replace(/\D/g, "").slice(0, 16);
    return digits.match(/.{1,4}/g)?.join(" ") ?? "";
}

function formatExpiry(value: string): string {
    const digits = value.replace(/\D/g, "").slice(0, 4);
    if (digits.length <= 2) return digits;
    return `${digits.slice(0, 2)}/${digits.slice(2)}`;
}

function formatCvv(value: string): string {
    return value.replace(/\D/g, "").slice(0, 3);
}

function formatPostalCode(value: string): string {
    return value.replace(/\s+/g, "").toUpperCase().slice(0, 8);
}

// AR CPA accepts 4-digit legacy ("1414") or the newer alphanumeric form
// ("C1414AAB"). Both are valid Correo Argentino formats.
const CPA_REGEX = /^(\d{4}|[A-Z]\d{4}[A-Z]{3})$/;

function validateField(key: FieldKey, value: string): string | undefined {
    switch (key) {
        case "cardNumber": {
            const digits = value.replace(/\s+/g, "");
            if (digits.length === 0) return t.pay.errors.cardRequired;
            if (!/^\d{16}$/.test(digits) || !luhnValid(digits)) {
                return t.pay.errors.cardInvalid;
            }
            return undefined;
        }
        case "expiry": {
            if (value.trim().length === 0) return t.pay.errors.expiryRequired;
            const m = value.match(/^(\d{2})\s*\/\s*(\d{2})$/);
            if (!m) return t.pay.errors.expiryInvalid;
            const month = Number(m[1]);
            const year = Number(m[2]);
            if (month < 1 || month > 12) return t.pay.errors.expiryInvalid;
            const currentYY = new Date().getFullYear() % 100;
            if (year < currentYY) return t.pay.errors.expiryPast;
            return undefined;
        }
        case "cvv": {
            if (value.length === 0) return t.pay.errors.cvvRequired;
            if (!/^\d{3}$/.test(value)) return t.pay.errors.cvvInvalid;
            return undefined;
        }
        case "holder":
            return value.trim().length === 0 ? t.pay.errors.holderRequired : undefined;
        case "street":
            return value.trim().length === 0 ? t.pay.errors.streetRequired : undefined;
        case "city":
            return value.trim().length === 0 ? t.pay.errors.cityRequired : undefined;
        case "province":
            return value.trim().length === 0 ? t.pay.errors.provinceRequired : undefined;
        case "postalCode": {
            const v = value.trim();
            if (v.length === 0) return t.pay.errors.postalRequired;
            if (!CPA_REGEX.test(v)) return t.pay.errors.postalInvalid;
            return undefined;
        }
    }
}

function validateAll(form: FormState): FieldErrors {
    const errors: FieldErrors = {};
    for (const key of FIELD_ORDER) {
        const err = validateField(key, form[key]);
        if (err) errors[key] = err;
    }
    return errors;
}

function formatAmount(cents: number, currency: string): string {
    return new Intl.NumberFormat("es-AR", { style: "currency", currency }).format(cents / 100);
}

export default function ShipperPaymentPage() {
    const { id } = useParams<{ id: string }>();
    const navigate = useNavigate();
    const shipmentId = Number(id);

    const [shipment, setShipment] = useState<ShipmentDetail | null>(null);
    const [loadError, setLoadError] = useState<string | null>(null);
    const [form, setForm] = useState<FormState>(EMPTY_FORM);
    const [touched, setTouched] = useState<TouchedMap>({});
    const [submitAttempted, setSubmitAttempted] = useState(false);
    const [submitting, setSubmitting] = useState(false);
    const [submitError, setSubmitError] = useState<string | null>(null);

    const formRef = useRef<HTMLFormElement>(null);
    const [cancelDialogOpen, setCancelDialogOpen] = useState(false);
    const cancelDialogRef = useRef<HTMLDialogElement>(null);

    useEffect(() => {
        const el = cancelDialogRef.current;
        if (!el) return;
        if (cancelDialogOpen) {
            el.showModal();
            const first = el.querySelector<HTMLElement>(
                'button:not([disabled]), [href], [tabindex]:not([tabindex="-1"])'
            );
            first?.focus();
        }
    }, [cancelDialogOpen]);

    useEffect(() => {
        const previousTitle = document.title;
        document.title = t.pay.documentTitle;
        return () => {
            document.title = previousTitle;
        };
    }, []);

    useEffect(() => {
        if (!Number.isFinite(shipmentId)) {
            setLoadError(t.pay.errors.generic);
            return;
        }
        getShipmentDetail(shipmentId)
            .then(setShipment)
            .catch((e: unknown) => {
                if (e instanceof ApiError && (e.status === 404 || e.status === 403)) {
                    navigate("/shipper/shipments", { replace: true });
                    return;
                }
                setLoadError(t.pay.errors.generic);
            });
    }, [shipmentId, navigate]);

    const fieldErrors = validateAll(form);

    function shouldShowError(key: FieldKey): boolean {
        return Boolean((touched[key] || submitAttempted) && fieldErrors[key]);
    }

    function update<K extends FieldKey>(key: K, raw: string) {
        let next = raw;
        if (key === "cardNumber") next = formatCardNumber(raw);
        else if (key === "expiry") next = formatExpiry(raw);
        else if (key === "cvv") next = formatCvv(raw);
        else if (key === "postalCode") next = formatPostalCode(raw);
        setForm((prev) => ({ ...prev, [key]: next }));
    }

    function markTouched(key: FieldKey) {
        setTouched((prev) => (prev[key] ? prev : { ...prev, [key]: true }));
    }

    function focusFirstInvalid(errors: FieldErrors) {
        const firstInvalid = FIELD_ORDER.find((k) => errors[k]);
        if (!firstInvalid) return;
        const el = formRef.current?.querySelector<HTMLElement>(`#${INPUT_ID[firstInvalid]}`);
        el?.focus();
    }

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        if (submitting || !shipment) return;
        setSubmitAttempted(true);
        setSubmitError(null);

        const errors = validateAll(form);
        if (Object.keys(errors).length > 0) {
            focusFirstInvalid(errors);
            return;
        }

        setSubmitting(true);
        try {
            const result = await createShipmentPayment(shipmentId);
            if (result.state === "escrowed") {
                navigate(`/shipper/shipments/${shipmentId}/pay/success`);
                return;
            }
            setSubmitError(t.pay.errors.generic);
        } catch {
            setSubmitError(t.pay.errors.generic);
        } finally {
            setSubmitting(false);
        }
    }

    function errorIdFor(key: FieldKey): string {
        return `${INPUT_ID[key]}-error`;
    }

    function ariaPropsFor(key: FieldKey) {
        const invalid = shouldShowError(key);
        return {
            "aria-invalid": invalid || undefined,
            "aria-describedby": invalid ? errorIdFor(key) : undefined,
        } as const;
    }

    function FieldError({ field }: { field: FieldKey }) {
        if (!shouldShowError(field)) return null;
        return (
            <p className="shipperPaymentFieldError" id={errorIdFor(field)}>
                {fieldErrors[field]}
            </p>
        );
    }

    return (
        <main className="page shipperMain shipperPaymentPage" id="main">
            <div className="container shipperPaymentContainer">
                <header className="shipperPaymentHeader">
                    <h1 className="sectionTitle">{t.pay.title}</h1>
                    <p className="sectionLead">{t.pay.lead}</p>
                </header>

                {loadError && (
                    <div className="shipmentErrorPanel" role="alert">
                        <p>{loadError}</p>
                    </div>
                )}

                {shipment && (
                    <form
                        ref={formRef}
                        className="shipperPaymentForm"
                        onSubmit={handleSubmit}
                        noValidate
                        aria-busy={submitting || undefined}
                    >
                        <div className="shipperPaymentSummary">
                            <span className="shipperPaymentSummaryLabel">{t.pay.amountLabel}</span>
                            <span className="shipperPaymentSummaryAmount">
                                {formatAmount(shipment.amount_cents, shipment.currency)}
                            </span>
                        </div>

                        <p className="shipperPaymentRequiredHint">{t.pay.requiredHint}</p>

                        <fieldset className="shipperPaymentSection" disabled={submitting}>
                            <legend className="shipperPaymentSectionLegend">
                                {t.pay.sectionCardTitle}
                            </legend>
                            <label className="shipperPaymentLabel" htmlFor="payCardNumber">
                                {t.pay.fields.cardNumber.label}
                                <input
                                    id="payCardNumber"
                                    name="cardNumber"
                                    type="text"
                                    inputMode="numeric"
                                    autoComplete="cc-number"
                                    placeholder={t.pay.fields.cardNumber.placeholder}
                                    value={form.cardNumber}
                                    onChange={(e) => update("cardNumber", e.target.value)}
                                    onBlur={() => markTouched("cardNumber")}
                                    required
                                    {...ariaPropsFor("cardNumber")}
                                />
                                <FieldError field="cardNumber" />
                            </label>
                            <div className="shipperPaymentRow">
                                <label className="shipperPaymentLabel" htmlFor="payExpiry">
                                    {t.pay.fields.expiry.label}
                                    <input
                                        id="payExpiry"
                                        name="expiry"
                                        type="text"
                                        inputMode="numeric"
                                        autoComplete="cc-exp"
                                        placeholder={t.pay.fields.expiry.placeholder}
                                        value={form.expiry}
                                        onChange={(e) => update("expiry", e.target.value)}
                                        onBlur={() => markTouched("expiry")}
                                        required
                                        {...ariaPropsFor("expiry")}
                                    />
                                    <FieldError field="expiry" />
                                </label>
                                <label className="shipperPaymentLabel" htmlFor="payCvv">
                                    {t.pay.fields.cvv.label}
                                    <input
                                        id="payCvv"
                                        name="cvv"
                                        type="password"
                                        inputMode="numeric"
                                        autoComplete="cc-csc"
                                        placeholder={t.pay.fields.cvv.placeholder}
                                        value={form.cvv}
                                        onChange={(e) => update("cvv", e.target.value)}
                                        onBlur={() => markTouched("cvv")}
                                        required
                                        {...ariaPropsFor("cvv")}
                                    />
                                    <FieldError field="cvv" />
                                </label>
                            </div>
                            <label className="shipperPaymentLabel" htmlFor="payHolder">
                                {t.pay.fields.holder.label}
                                <input
                                    id="payHolder"
                                    name="holder"
                                    type="text"
                                    autoComplete="cc-name"
                                    placeholder={t.pay.fields.holder.placeholder}
                                    value={form.holder}
                                    onChange={(e) => update("holder", e.target.value)}
                                    onBlur={() => markTouched("holder")}
                                    required
                                    {...ariaPropsFor("holder")}
                                />
                                <FieldError field="holder" />
                            </label>
                        </fieldset>

                        <fieldset className="shipperPaymentSection" disabled={submitting}>
                            <legend className="shipperPaymentSectionLegend">
                                {t.pay.sectionAddressTitle}
                            </legend>
                            <label className="shipperPaymentLabel" htmlFor="payStreet">
                                {t.pay.fields.street.label}
                                <input
                                    id="payStreet"
                                    name="street"
                                    type="text"
                                    autoComplete="address-line1"
                                    placeholder={t.pay.fields.street.placeholder}
                                    value={form.street}
                                    onChange={(e) => update("street", e.target.value)}
                                    onBlur={() => markTouched("street")}
                                    required
                                    {...ariaPropsFor("street")}
                                />
                                <FieldError field="street" />
                            </label>
                            <div className="shipperPaymentRow">
                                <label className="shipperPaymentLabel" htmlFor="payCity">
                                    {t.pay.fields.city.label}
                                    <input
                                        id="payCity"
                                        name="city"
                                        type="text"
                                        autoComplete="address-level2"
                                        placeholder={t.pay.fields.city.placeholder}
                                        value={form.city}
                                        onChange={(e) => update("city", e.target.value)}
                                        onBlur={() => markTouched("city")}
                                        required
                                        {...ariaPropsFor("city")}
                                    />
                                    <FieldError field="city" />
                                </label>
                                <label className="shipperPaymentLabel" htmlFor="payProvince">
                                    {t.pay.fields.province.label}
                                    <ProvinceSelect
                                        id="payProvince"
                                        value={form.province}
                                        onChange={(v) => {
                                            update("province", v);
                                            markTouched("province");
                                        }}
                                        placeholder={t.pay.fields.province.placeholder}
                                        onBlur={() => markTouched("province")}
                                        required
                                        {...ariaPropsFor("province")}
                                    />
                                    <FieldError field="province" />
                                </label>
                            </div>
                            <label className="shipperPaymentLabel" htmlFor="payPostalCode">
                                {t.pay.fields.postalCode.label}
                                <input
                                    id="payPostalCode"
                                    name="postalCode"
                                    type="text"
                                    inputMode="text"
                                    autoComplete="postal-code"
                                    placeholder={t.pay.fields.postalCode.placeholder}
                                    value={form.postalCode}
                                    onChange={(e) => update("postalCode", e.target.value)}
                                    onBlur={() => markTouched("postalCode")}
                                    required
                                    {...ariaPropsFor("postalCode")}
                                />
                                <FieldError field="postalCode" />
                            </label>
                        </fieldset>

                        {submitError && (
                            <div className="shipperPaymentError" role="alert">
                                {submitError}
                            </div>
                        )}

                        <div className="shipperPaymentActions">
                            <Button
                                variant="ghost"
                                size="default"
                                type="button"
                                onClick={() => setCancelDialogOpen(true)}
                                disabled={submitting}
                            >
                                {t.pay.cancelLabel}
                            </Button>
                            <Button
                                variant="primary"
                                size="default"
                                type="submit"
                                disabled={submitting}
                            >
                                {submitting ? t.pay.ctaLoading : t.pay.cta}
                            </Button>
                        </div>
                    </form>
                )}

                {cancelDialogOpen && (
                    <dialog
                        className="confirmDialog"
                        ref={cancelDialogRef}
                        data-action="cancel_checkout"
                        aria-labelledby="cancelCheckoutTitle"
                        onCancel={(e) => { e.preventDefault(); setCancelDialogOpen(false); }}
                    >
                        <div className="confirmDialogBody">
                            <div className="confirmDialogCancelmark" aria-hidden="true">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                                    <circle cx="12" cy="12" r="9" />
                                    <line x1="9" y1="9" x2="15" y2="15" />
                                    <line x1="15" y1="9" x2="9" y2="15" />
                                </svg>
                            </div>
                            <h2 className="confirmDialogTitle" id="cancelCheckoutTitle">
                                {t.pay.cancelConfirm.title}
                            </h2>
                            <p className="confirmDialogText">{t.pay.cancelConfirm.text}</p>
                            <div className="confirmDialogActions">
                                <Button variant="ghost" onClick={() => navigate(-1)}>
                                    {t.pay.cancelConfirm.leave}
                                </Button>
                                <Button variant="primary" className="confirmDialogConfirmBtn" onClick={() => setCancelDialogOpen(false)}>
                                    {t.pay.cancelConfirm.stay}
                                </Button>
                            </div>
                        </div>
                    </dialog>
                )}
            </div>
        </main>
    );
}
