import type { ShipmentState } from "../../api/shipments";
import { shipmentsSharedContent } from "./shipmentsSharedContent";

interface Props {
    state: ShipmentState;
}

export function ShipmentStateChip({ state }: Props) {
    const label = shipmentsSharedContent.state[state];
    return (
        <span className={`shipmentStateChip shipmentStateChip--${state}`}>
            {label}
        </span>
    );
}
