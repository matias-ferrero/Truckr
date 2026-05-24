import { useEffect, useState } from "react";
import { listCarrierCargoOffers } from "../api/carrierCargoOffers";
import { offersAndShipmentsContent } from "../pages/carrier/offersAndShipmentsContent";

export default function CarrierBadge() {
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
        <span className="appHeaderBadge" aria-label={headerText.pendingBadgeAria(pendingCount)} aria-live="polite">
            {headerText.pendingBadge(pendingCount)}
        </span>
    );
}
