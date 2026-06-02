import { type Review } from "../../api/reviews";
import { reviewsContent } from "./reviewsContent";
import { ReviewForm } from "./ReviewForm";

interface Props {
    shipmentId: number;
    existingReview?: Review | null;
    onCreated?: (review: Review) => void;
}

export function ShipperReviewForm({ shipmentId, existingReview, onCreated }: Props) {
    return (
        <ReviewForm
            shipmentId={shipmentId}
            existingReview={existingReview}
            onCreated={onCreated}
            content={reviewsContent.shipperReview}
            id="shipperReview"
        />
    );
}

export default ShipperReviewForm;
