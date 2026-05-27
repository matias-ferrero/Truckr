import type { PaymentState } from "../../api/shipments";
import { shipmentsSharedContent } from "./shipmentsSharedContent";

interface Props {
    paymentState: PaymentState;
}

export function PaymentStateChip({ paymentState }: Props) {
    const label = shipmentsSharedContent.paymentState[paymentState];
    return (
        <span className={`paymentStateChip paymentStateChip--${paymentState}`}>
            {label}
        </span>
    );
}
