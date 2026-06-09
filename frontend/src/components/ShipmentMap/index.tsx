import { useEffect, useRef, useState } from "react";
import { getGoogleMapsLoader } from "../../lib/gmaps";
import { shipmentMapContent as c } from "./shipmentMapContent";

// <ShipmentMap /> — US51 / REQ-FE-00028.
//
// Two-pin map (origin green, destination red) with a driving route polyline for
// the shipment detail slot (REQ-FE-00024). Reuses the shared
// `getGoogleMapsLoader` singleton so the union of requested libraries stays
// consistent with the AddressPicker / RadiusControl / CargoMapPreview
// map-bearing components.
//
// Reusable by construction: the props are coordinate-only, so the same map can
// later be mounted on the offer-detail preview without rework.

/** A resolved geographic pin. `label` feeds the marker hover title. */
export type LatLng = { lat: number; lng: number; label?: string };

/**
 * Parse the DECIMAL(9,6) string coordinates the backend emits (e.g.
 * `"-34.603722"`) into a {@link LatLng}, or `null` when either side is
 * missing/non-finite. Centralised so the map and the deep-link buttons share
 * one defensive parse (AC3).
 */
export function toLatLng(
    lat: string | number | null | undefined,
    lng: string | number | null | undefined,
    label?: string,
): LatLng | null {
    if (lat === null || lat === undefined || lng === null || lng === undefined) return null;
    const latN = typeof lat === "number" ? lat : Number(lat);
    const lngN = typeof lng === "number" ? lng : Number(lng);
    if (!Number.isFinite(latN) || !Number.isFinite(lngN)) return null;
    return { lat: latN, lng: lngN, label };
}

export interface ShipmentMapProps {
    origin: LatLng | null;
    destination: LatLng | null;
    /** Canvas height in px on desktop. Defaults to 300. */
    height?: number;
}

type LoadState = "idle" | "loading" | "ready" | "error";

// Google's stock colored markers. Static assets served by Google, independent
// of our API key — the green/red convention is universally legible (AC1).
const ORIGIN_ICON = "https://maps.google.com/mapfiles/ms/icons/green-dot.png";
const DESTINATION_ICON = "https://maps.google.com/mapfiles/ms/icons/red-dot.png";

export function ShipmentMap({ origin, destination, height = 300 }: ShipmentMapProps) {
    const apiKey = (import.meta.env.VITE_GOOGLE_MAPS_API_KEY as string | undefined) ?? "";
    const both = origin !== null && destination !== null;

    const [loadState, setLoadState] = useState<LoadState>(
        !both ? "idle" : apiKey ? "loading" : "error",
    );
    const mapElRef = useRef<HTMLDivElement | null>(null);
    const mapRef = useRef<google.maps.Map | null>(null);
    const markersRef = useRef<google.maps.Marker[]>([]);
    const rendererRef = useRef<google.maps.DirectionsRenderer | null>(null);

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
                if (!cancelled) setLoadState("ready");
            })
            .catch(() => {
                if (!cancelled) setLoadState("error");
            });
        return () => {
            cancelled = true;
        };
    }, [apiKey, both]);

    useEffect(() => {
        if (loadState !== "ready" || !origin || !destination || !mapElRef.current) return;

        const bounds = new google.maps.LatLngBounds();
        bounds.extend({ lat: origin.lat, lng: origin.lng });
        bounds.extend({ lat: destination.lat, lng: destination.lng });

        // Reinitialise if the canvas div remounted onto a fresh DOM element.
        if (!mapRef.current || mapRef.current.getDiv() !== mapElRef.current) {
            mapRef.current = new google.maps.Map(mapElRef.current, {
                disableDefaultUI: true,
                zoomControl: true,
                clickableIcons: false,
            });
        }

        for (const marker of markersRef.current) marker.setMap(null);
        markersRef.current = [
            new google.maps.Marker({
                map: mapRef.current,
                position: { lat: origin.lat, lng: origin.lng },
                title: origin.label ?? c.originPinTitle,
                icon: ORIGIN_ICON,
            }),
            new google.maps.Marker({
                map: mapRef.current,
                position: { lat: destination.lat, lng: destination.lng },
                title: destination.label ?? c.destinationPinTitle,
                icon: DESTINATION_ICON,
            }),
        ];

        // Pad so both pins clear the map chrome; matches CargoMapPreview rhythm.
        mapRef.current.fitBounds(bounds, 48);

        // Draw the driving route between the two pins. Fire-and-forget: if the
        // Directions API fails the pins are still shown (graceful degradation).
        let cancelled = false;
        const svc = new google.maps.DirectionsService();
        svc.route(
            {
                origin:      { lat: origin.lat, lng: origin.lng },
                destination: { lat: destination.lat, lng: destination.lng },
                travelMode:  google.maps.TravelMode.DRIVING,
            },
            (result, status) => {
                if (cancelled || status !== "OK" || !result) return;
                if (!rendererRef.current) {
                    rendererRef.current = new google.maps.DirectionsRenderer({
                        suppressMarkers:  true,   // keep our green/red custom pins
                        preserveViewport: true,   // fitBounds already ran — don't re-zoom
                        polylineOptions: {
                            strokeColor:   "#0041c2",
                            strokeOpacity: 1,
                            strokeWeight:  6,
                        },
                    });
                    rendererRef.current.setMap(mapRef.current);
                }
                rendererRef.current.setDirections(result);
            },
        );

        return () => {
            cancelled = true;
            rendererRef.current?.setMap(null);
            rendererRef.current = null;
        };
        // Depend on the primitive coordinates, not the object refs: callers
        // recompute the pins each render (fresh objects), so keying on the
        // objects would rebuild markers and re-fitBounds on every unrelated
        // re-render — visibly snapping the map back. Re-run only when a
        // coordinate actually changes.
    }, [loadState, origin?.lat, origin?.lng, destination?.lat, destination?.lng]);

    if (!both) {
        return (
            <div className="shipmentMap shipmentMapMessage" data-state="unavailable" role="status">
                <p className="shipmentMapMessageText">{c.unavailable}</p>
            </div>
        );
    }

    if (loadState === "error") {
        return (
            <div className="shipmentMap shipmentMapMessage" data-state="service_unavailable" role="status">
                <p className="shipmentMapMessageText">{c.serviceUnavailable}</p>
            </div>
        );
    }

    return (
        <div
            ref={mapElRef}
            className="shipmentMap shipmentMapCanvas"
            data-state={loadState}
            data-testid="shipment-map-canvas"
            role="region"
            aria-label={c.regionLabel}
            aria-busy={loadState === "loading" ? "true" : undefined}
            style={{ height: `${height}px` }}
        />
    );
}

export default ShipmentMap;
