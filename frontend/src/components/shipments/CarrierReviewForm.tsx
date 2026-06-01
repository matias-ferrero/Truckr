import { useState } from "react";
import { ApiError } from "../../api";
import { createCarrierReview, type Review } from "../../api/reviews";
import { Button } from "../ui/button";
import {
    REVIEW_BODY_MAX,
    REVIEW_MAX_RATING,
    REVIEW_MIN_RATING,
    reviewsContent as t,
} from "./reviewsContent";
import "../../styles/shipments.css";

interface Props {
    shipmentId: number;
    // When the backend already returned a carrier-authored review for this
    // shipment, US39 passes it here so the form renders its read-only
    // "already submitted" state straight away (AC7).
    existingReview?: Review | null;
    // Fired after a successful create so US39 can refetch the detail and emit
    // `truckr:shipment-updated`.
    onCreated?: (review: Review) => void;
}

const STARS = Array.from(
    { length: REVIEW_MAX_RATING - REVIEW_MIN_RATING + 1 },
    (_, i) => REVIEW_MIN_RATING + i,
);

function StarDisplay({ rating }: { rating: number }) {
    return (
        <span className="carrierReviewStarsStatic" aria-label={t.carrierReview.starLabel(rating)}>
            {STARS.map((n) => (
                <span key={n} aria-hidden="true" className="carrierReviewStarGlyph">
                    {n <= rating ? "★" : "☆"}
                </span>
            ))}
        </span>
    );
}

export function CarrierReviewForm({ shipmentId, existingReview = null, onCreated }: Props) {
    const [created, setCreated] = useState<Review | null>(existingReview);
    const [rating, setRating] = useState(0);
    const [body, setBody] = useState("");
    const [submitting, setSubmitting] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [ratingError, setRatingError] = useState<string | null>(null);

    // ── Submitted state: disabled form replaced by the created review (AC7) ──
    if (created) {
        return (
            <section className="carrierReviewCard carrierReviewCard--done" aria-labelledby="carrierReviewDoneHeading">
                <h3 className="carrierReviewTitle" id="carrierReviewDoneHeading">
                    {t.carrierReview.success.heading}
                </h3>
                <div className="carrierReviewDoneRating">
                    <span className="carrierReviewDoneLabel">{t.carrierReview.success.yourRating}</span>
                    <StarDisplay rating={created.rating} />
                </div>
                {created.body && <p className="carrierReviewDoneBody">{created.body}</p>}
            </section>
        );
    }

    function mapError(e: unknown): string {
        if (e instanceof ApiError) {
            if (e.status === 409 && e.code === "conflict") {
                // Backend message distinguishes not-delivered vs already-reviewed;
                // fall back to the most likely cause for the carrier flow.
                return t.carrierReview.errors.alreadyReviewed;
            }
            if (e.status === 403) return t.carrierReview.errors.forbidden;
            if (e.status === 422) return t.carrierReview.errors.bodyTooLong;
        }
        return t.carrierReview.errors.generic;
    }

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        if (submitting) return;
        setError(null);

        if (rating < REVIEW_MIN_RATING || rating > REVIEW_MAX_RATING) {
            setRatingError(t.carrierReview.errors.ratingRequired);
            return;
        }
        if (body.length > REVIEW_BODY_MAX) {
            setError(t.carrierReview.errors.bodyTooLong);
            return;
        }
        setRatingError(null);

        setSubmitting(true);
        try {
            const review = await createCarrierReview(shipmentId, {
                rating,
                body: body.trim().length > 0 ? body.trim() : null,
            });
            setCreated(review);
            onCreated?.(review);
        } catch (err) {
            setError(mapError(err));
        } finally {
            setSubmitting(false);
        }
    }

    return (
        <section className="carrierReviewCard" aria-labelledby="carrierReviewHeading">
            <header className="carrierReviewHeader">
                <h3 className="carrierReviewTitle" id="carrierReviewHeading">
                    {t.carrierReview.title}
                </h3>
                <p className="carrierReviewLead">{t.carrierReview.lead}</p>
            </header>

            <form className="carrierReviewForm" onSubmit={handleSubmit} noValidate aria-busy={submitting || undefined}>
                <fieldset
                    className="carrierReviewFieldset"
                    disabled={submitting}
                    role="radiogroup"
                    aria-labelledby="carrierReviewRatingLegend"
                    aria-describedby={ratingError ? "carrierReviewRatingError" : undefined}
                >
                    <legend className="carrierReviewLegend" id="carrierReviewRatingLegend">
                        {t.carrierReview.ratingLabel}
                    </legend>
                    <div className="carrierReviewStars">
                        {STARS.map((n) => (
                            <button
                                key={n}
                                type="button"
                                role="radio"
                                aria-checked={rating === n}
                                aria-label={t.carrierReview.starLabel(n)}
                                className={
                                    "carrierReviewStar" + (n <= rating ? " carrierReviewStar--on" : "")
                                }
                                onClick={() => {
                                    setRating(n);
                                    setRatingError(null);
                                }}
                            >
                                <span aria-hidden="true">{n <= rating ? "★" : "☆"}</span>
                            </button>
                        ))}
                    </div>
                    {ratingError && (
                        <p className="carrierReviewFieldError" id="carrierReviewRatingError">
                            {ratingError}
                        </p>
                    )}
                </fieldset>

                <label className="carrierReviewLabel" htmlFor="carrierReviewBody">
                    {t.carrierReview.bodyLabel}
                    <textarea
                        id="carrierReviewBody"
                        className="carrierReviewTextarea"
                        value={body}
                        maxLength={REVIEW_BODY_MAX}
                        rows={4}
                        placeholder={t.carrierReview.bodyPlaceholder}
                        onChange={(e) => setBody(e.target.value)}
                        disabled={submitting}
                    />
                    <span className="carrierReviewCounter" aria-hidden="true">
                        {t.carrierReview.bodyCounter(body.length, REVIEW_BODY_MAX)}
                    </span>
                </label>

                {error && (
                    <div className="carrierReviewError" role="alert">
                        {error}
                    </div>
                )}

                <div className="carrierReviewActions">
                    <Button variant="primary" size="default" type="submit" disabled={submitting}>
                        {submitting ? t.carrierReview.submitLoading : t.carrierReview.submit}
                    </Button>
                </div>
            </form>
        </section>
    );
}

export default CarrierReviewForm;
