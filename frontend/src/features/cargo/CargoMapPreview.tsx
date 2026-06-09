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
    /** When supplied, the stored distance is shown as-is and the client-side
     *  DistanceMatrixService call is skipped entirely. */
    distanceKm?: number;
    /** Set to false to suppress the section title (e.g. in detail view where
     *  the parent section already provides a heading). Defaults to true. */
    showTitle?: boolean;
}

type LoadState = "idle" | "loading" | "ready" | "error";
type DistanceState = "idle" | "loading" | "ready" | "error";

const m = cargosContent.form.mapPreview;

export function CargoMapPreview({ pickup, delivery, distanceKm, showTitle = true }: CargoMapPreviewProps) {
    const apiKey = (import.meta.env.VITE_GOOGLE_MAPS_API_KEY as string | undefined) ?? "";
    const both = pickup !== null && delivery !== null;

    const [loadState, setLoadState] = useState<LoadState>(both && apiKey ? "loading" : "idle");
    const [routeDistanceKm, setRouteDistanceKm] = useState<number | null>(null);
    const [distanceState, setDistanceState] = useState<DistanceState>("idle");
    const mapElRef = useRef<HTMLDivElement | null>(null);
    const mapRef = useRef<google.maps.Map | null>(null);
    const markersRef = useRef<google.maps.Marker[]>([]);
    const rendererRef = useRef<google.maps.DirectionsRenderer | null>(null);

    useEffect(() => {
        if (!both) {
            setLoadState("idle");
            setDistanceState("idle");
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

        let cancelled = false;

        const bounds = new google.maps.LatLngBounds();
        bounds.extend({ lat: pickup.lat, lng: pickup.lng });
        bounds.extend({ lat: delivery.lat, lng: delivery.lng });

        // If the canvas div remounted (e.g. after clearing an address), the old
        // Map instance points to a detached element — reinitialise on the new div.
        if (!mapRef.current || mapRef.current.getDiv() !== mapElRef.current) {
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

        setDistanceState("loading");
        const svc = new google.maps.DirectionsService();
        svc.route(
            {
                origin:      { lat: pickup.lat, lng: pickup.lng },
                destination: { lat: delivery.lat, lng: delivery.lng },
                travelMode:  google.maps.TravelMode.DRIVING,
            },
            (result, status) => {
                if (cancelled) return;
                if (status === "OK" && result) {
                    if (!rendererRef.current) {
                        rendererRef.current = new google.maps.DirectionsRenderer({
                            suppressMarkers:  true,
                            preserveViewport: true,
                            polylineOptions: {
                                strokeColor:   "#0041c2",
                                strokeOpacity: 1,
                                strokeWeight:  6,
                            },
                        });
                        rendererRef.current.setMap(mapRef.current);
                    }
                    rendererRef.current.setDirections(result);
                    const legMeters = result.routes[0].legs[0].distance.value;
                    setRouteDistanceKm(distanceKm ?? legMeters / 1000);
                    setDistanceState("ready");
                } else {
                    setRouteDistanceKm(null);
                    setDistanceState("error");
                }
            },
        );

        return () => {
            cancelled = true;
            rendererRef.current?.setMap(null);
            rendererRef.current = null;
        };
    }, [loadState, pickup, delivery, distanceKm]);

    if (!both) {
        return (
            <div className="cargoMapPreview cargoMapPreviewIdle" data-state="idle">
                {showTitle && <p className="cargoMapPreviewTitle">{m.title}</p>}
                <p className="cargoMapPreviewHelp">{m.help}</p>
            </div>
        );
    }

    if (loadState === "error") {
        return (
            <div className="cargoMapPreview cargoMapPreviewError" data-state="error" role="status">
                {showTitle && <p className="cargoMapPreviewTitle">{m.title}</p>}
                <p className="cargoMapPreviewHelp">{m.unavailable}</p>
            </div>
        );
    }

    return (
        <div className="cargoMapPreview" data-state={loadState}>
            {showTitle && <p className="cargoMapPreviewTitle">{m.title}</p>}
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
            {distanceState === "loading" && (
                <p
                    className="cargoMapPreviewDistance"
                    data-testid="cargo-map-preview-distance-loading"
                >
                    {m.distanceLoading}
                </p>
            )}
            {distanceState === "ready" && routeDistanceKm != null && (
                <p
                    className="cargoMapPreviewDistance"
                    data-testid="cargo-map-preview-distance"
                >
                    {m.distance(routeDistanceKm)}
                </p>
            )}
            {distanceState === "error" && (
                <p
                    className="cargoMapPreviewDistance"
                    data-testid="cargo-map-preview-distance-error"
                >
                    {m.distanceUnavailable}
                </p>
            )}
        </div>
    );
}

export default CargoMapPreview;
