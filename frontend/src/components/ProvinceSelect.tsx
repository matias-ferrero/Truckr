import { Select } from "./ui/select";

export const AR_PROVINCES = [
    "Buenos Aires",
    "CABA",
    "Catamarca",
    "Chaco",
    "Chubut",
    "Córdoba",
    "Corrientes",
    "Entre Ríos",
    "Formosa",
    "Jujuy",
    "La Pampa",
    "La Rioja",
    "Mendoza",
    "Misiones",
    "Neuquén",
    "Río Negro",
    "Salta",
    "San Juan",
    "San Luis",
    "Santa Cruz",
    "Santa Fe",
    "Santiago del Estero",
    "Tierra del Fuego, Antártida e Islas del Atlántico Sur",
    "Tucumán",
] as const;

export type Province = (typeof AR_PROVINCES)[number];

type Props = {
    id: string;
    value: string;
    onChange: (value: string) => void;
    required?: boolean;
    /** Text for the blank/empty option shown when the field is optional. */
    placeholder?: string;
};

export default function ProvinceSelect(
    { id, value, onChange, required, placeholder, ...rest }:
        Props & Omit<React.SelectHTMLAttributes<HTMLSelectElement>, keyof Props>,
) {
    // When the field is required, the placeholder is "pick one" — render it
    // disabled+hidden so users can't re-select the empty value, and only while
    // the field is still empty.
    // When the field is optional, the placeholder is "any/none" — render it as
    // a normal selectable option so users can clear their choice.
    const isRequired = required === true;
    const placeholderLabel = placeholder ?? "—";
    return (
        <Select
            id={id}
            value={value}
            onChange={(e) => onChange(e.target.value)}
            required={required}
            {...rest}
        >
            {isRequired
                ? value === "" && (
                    <option value="" disabled hidden>
                        {placeholderLabel}
                    </option>
                )
                : <option value="">{placeholderLabel}</option>}
            {AR_PROVINCES.map((p) => (
                <option key={p} value={p}>
                    {p}
                </option>
            ))}
        </Select>
    );
}
