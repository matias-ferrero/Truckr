import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { listMyVehicles, Vehicle } from "../api/vehicles";
import { Select } from "./ui/select";
import { FormField } from "./ui/form-field";

export type VehicleSelectProps = {
    value: number | null;
    onChange: (id: number | null) => void;
    label?: string;
    placeholder?: string;
    autoSelectIfSingle?: boolean;
};

type LoadState =
    | { status: "loading" }
    | { status: "ready"; items: Vehicle[] }
    | { status: "error"; message: string };

export default function VehicleSelect({
    value,
    onChange,
    label = "Vehículo",
    placeholder = "Seleccioná un vehículo",
    autoSelectIfSingle = true,
}: VehicleSelectProps) {
    const [state, setState] = useState<LoadState>({ status: "loading" });

    useEffect(() => {
        let cancelled = false;
        (async () => {
            try {
                const res = await listMyVehicles(1);
                if (cancelled) return;
                setState({ status: "ready", items: res.items });
                if (autoSelectIfSingle && res.items.length === 1 && value == null) {
                    onChange(res.items[0]!.id);
                }
            } catch (e) {
                if (!cancelled) {
                    setState({ status: "error", message: (e as Error).message });
                }
            }
        })();
        return () => {
            cancelled = true;
        };
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []);

    if (state.status === "loading") {
        return (
            <FormField id="vehicle-select" label={label}>
                <Select id="vehicle-select" disabled value="" onChange={() => {}} aria-busy="true">
                    <option>Cargando tu flota…</option>
                </Select>
            </FormField>
        );
    }

    if (state.status === "error") {
        return (
            <FormField
                id="vehicle-select"
                label={label}
                error={`No pudimos cargar tu flota: ${state.message}`}
            >
                <span aria-hidden="true" className="hidden" />
            </FormField>
        );
    }

    if (state.items.length === 0) {
        return (
            <FormField
                id="vehicle-select"
                label={label}
                help={
                    <>
                        Todavía no agregaste vehículos.{" "}
                        <Link to="/carrier/vehicle/new" className="underline">
                            Agregá el primero
                        </Link>
                        .
                    </>
                }
            >
                <span aria-hidden="true" className="hidden" />
            </FormField>
        );
    }

    return (
        <FormField id="vehicle-select" label={label}>
            <Select
                id="vehicle-select"
                value={value ?? ""}
                onChange={(e) => {
                    const v = e.target.value;
                    onChange(v ? Number(v) : null);
                }}
            >
                <option value="">{placeholder}</option>
                {state.items.map((v) => (
                    <option key={v.id} value={v.id}>
                        {v.make} {v.model} — {v.plate}
                    </option>
                ))}
            </Select>
        </FormField>
    );
}
