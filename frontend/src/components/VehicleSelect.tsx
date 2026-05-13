import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { listMyVehicles, Vehicle } from "../api/vehicles";

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

// Reusable dropdown for picking one of the carrier's vehicles. Stays standalone
// for now — REQ-FE-00016 mounts it inside the TransportWindow form.
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
                // Use a generous page size so the typical carrier sees the
                // full fleet in one shot. Pagy caps at 100 by default.
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
            <div className="field">
                <span aria-hidden="true">{label}</span>
                <p role="status" aria-busy="true">Cargando tu flota…</p>
            </div>
        );
    }

    if (state.status === "error") {
        return (
            <div className="field">
                <label htmlFor="vehicle-select">{label}</label>
                <p id="vehicle-select-error" className="fieldError" role="alert">
                    No pudimos cargar tu flota: {state.message}
                </p>
            </div>
        );
    }

    if (state.items.length === 0) {
        return (
            <div className="field">
                <label htmlFor="vehicle-select">{label}</label>
                <p className="emptyFleetHint">
                    Todavía no registraste vehículos.{" "}
                    <Link to="/carrier/vehicle/new" className="link">
                        Registrá el primero
                    </Link>.
                </p>
            </div>
        );
    }

    return (
        <div className="field">
            <label htmlFor="vehicle-select">{label}</label>
            <select
                id="vehicle-select"
                className="input"
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
            </select>
        </div>
    );
}
