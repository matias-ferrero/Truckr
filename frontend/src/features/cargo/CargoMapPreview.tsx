import { useEffect, useRef, useState } from "react";
import { getGoogleMapsLoader } from "../../lib/gmaps";
import type { AddressPickerValue } from "../../components/AddressPicker";
import { cargosContent } from "./cargosContent";

// TODO(REQ-FE-00028): replace with the shared <ShipmentMap /> once US51 lands.
// This minimal preview covers AC5 of US49 in isolation — two pins, fitBounds,
// no other map chrome. When ShipmentMap exports, swap the body and delete this
// file.

export interface CargoMapPreviewProps {
    pickup: AddressPickerValue | null;
    delivery: AddressPickerValue | null;
}

type LoadState = "idle" | "loading" | "ready" | "error";

const m = cargosContent.form.mapPreview;

export function CargoMapPreview({ pickup, delivery }: CargoMapPreviewProps) {
    const apiKey = (import.meta.env.VITE_GOOGLE_MAPS_API_KEY as string | undefined) ?? "";
    const both = pickup !== null && delivery !== null;

    const [loadState, setLoadState] = useState<LoadState>(both && apiKey ? "loading" : "idle");
    const mapElRef = useRef<HTMLDivElement | null>(null);
    const mapRef = useRef<google.maps.Map | null>(null);
    const markersRef = useRef<google.maps.Marker[]>([]);

    useEffect(() => {
        if (!both) {
            setLoadState("idle");
            return;
        }
        if (!apiKey) {
            setLoadState("error");
            return;
        }
        let cancelled = false;
        setLoadState((s) => (s === "ready" ? "ready" : "loading"));
        const loader = getGoogleMapsLoader(apiKey);
        loader
            .load()
            .then(() => {
                if (cancelled) return;
                setLoadState("ready");
            })
            .catch(() => {
                if (!cancelled) setLoadState("error");
            });
        return () => {
            cancelled = true;
        };
    }, [apiKey, both]);

    useEffect(() => {
        if (loadState !== "ready" || !pickup || !delivery || !mapElRef.current) return;

        const bounds = new google.maps.LatLngBounds();
        bounds.extend({ lat: pickup.lat, lng: pickup.lng });
        bounds.extend({ lat: delivery.lat, lng: delivery.lng });

        if (!mapRef.current) {
            mapRef.current = new google.maps.Map(mapElRef.current, {
                disableDefaultUI: true,
                zoomControl: true,
            });
        }

        for (const marker of markersRef.current) marker.setMap(null);
        markersRef.current = [
            new google.maps.Marker({
                map: mapRef.current,
                position: { lat: pickup.lat, lng: pickup.lng },
                label: "P",
                title: m.pickupLabel,
            }),
            new google.maps.Marker({
                map: mapRef.current,
                position: { lat: delivery.lat, lng: delivery.lng },
                label: "D",
                title: m.deliveryLabel,
            }),
        ];

        mapRef.current.fitBounds(bounds, 48);
    }, [loadState, pickup, delivery]);

    if (!both) {
        return (
            <div className="cargoMapPreview cargoMapPreviewIdle" data-state="idle">
                <p className="cargoMapPreviewTitle">{m.title}</p>
                <p className="cargoMapPreviewHelp">{m.help}</p>
            </div>
        );
    }

    if (loadState === "error") {
        return (
            <div className="cargoMapPreview cargoMapPreviewError" data-state="error" role="status">
                <p className="cargoMapPreviewTitle">{m.title}</p>
                <p className="cargoMapPreviewHelp">{m.unavailable}</p>
            </div>
        );
    }

    return (
        <div className="cargoMapPreview" data-state={loadState}>
            <p className="cargoMapPreviewTitle">{m.title}</p>
            <div
                ref={mapElRef}
                className="cargoMapPreviewCanvas"
                role="region"
                aria-label={m.regionLabel}
                data-testid="cargo-map-preview-canvas"
                data-pickup-lat={pickup.lat}
                data-pickup-lng={pickup.lng}
                data-delivery-lat={delivery.lat}
                data-delivery-lng={delivery.lng}
            />
        </div>
    );
}

export default CargoMapPreview;
