import { useEffect, useState } from "react";
import { listCarrierCargoOffers } from "../api/carrierCargoOffers";
import { offersAndShipmentsContent } from "../pages/carrier/offersAndShipmentsContent";

/** Live count of the carrier's pending cargo offers. Renders nothing while
    loading or when there are none. `className` lets callers style it for their
    surface (header pill vs. sidebar row badge). */
export default function CarrierBadge({ className = "appHeaderBadge" }: { className?: string }) {
    const [pendingCount, setPendingCount] = useState<number | null>(null);

    useEffect(() => {
        let cancelled = false;
        listCarrierCargoOffers("pending", 1)
            .then((res) => {
                if (!cancelled) setPendingCount(res.meta.total);
            })
            .catch(() => {
                if (!cancelled) setPendingCount(0);
            });
        return () => {
            cancelled = true;
        };
    }, []);

    if (pendingCount == null || pendingCount <= 0) return null;

    const headerText = offersAndShipmentsContent.header;

    return (
        <span className={className} aria-label={headerText.pendingBadgeAria(pendingCount)} aria-live="polite">
            {/* Visible content is just the count (a notification dot); the full
                phrase rides on aria-label for screen-reader users. */}
            {pendingCount}
        </span>
    );
}
