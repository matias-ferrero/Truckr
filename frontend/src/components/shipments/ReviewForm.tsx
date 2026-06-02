import { useState } from "react";
import { ApiError } from "../../api";
import { createShipmentReview, type Review } from "../../api/reviews";
import { Button } from "../ui/button";
import { REVIEW_BODY_MAX, REVIEW_MAX_RATING, REVIEW_MIN_RATING } from "./reviewsContent";
import "../../styles/shipments.css";

export interface ReviewFormContent {
    title: string;
    lead: string;
    ratingLabel: string;
    starLabel: (n: number) => string;
    bodyLabel: string;
    bodyPlaceholder: string;
    bodyCounter: (used: number, max: number) => string;
    submit: string;
    submitLoading: string;
    errors: {
        ratingRequired: string;
        bodyTooLong: string;
        alreadyReviewed: string;
        forbidden: string;
        generic: string;
    };
    success: { heading: string; yourRating: string };
}

interface Props {
    shipmentId: number;
    existingReview?: Review | null;
    onCreated?: (review: Review) => void;
    content: ReviewFormContent;
    id: string;
}

const STARS = Array.from(
    { length: REVIEW_MAX_RATING - REVIEW_MIN_RATING + 1 },
    (_, i) => REVIEW_MIN_RATING + i,
);

function StarDisplay({ rating, label }: { rating: number; label: string }) {
    return (
        <span className="carrierReviewStarsStatic" aria-label={label}>
            {STARS.map((n) => (
                <span key={n} aria-hidden="true" className="carrierReviewStarGlyph">
                    {n <= rating ? "★" : "☆"}
                </span>
            ))}
        </span>
    );
}

export function ReviewForm({ shipmentId, existingReview = null, onCreated, content: t, id }: Props) {
    const [created, setCreated] = useState<Review | null>(existingReview);
    const [rating, setRating] = useState(0);
    const [body, setBody] = useState("");
    const [submitting, setSubmitting] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [ratingError, setRatingError] = useState<string | null>(null);

    if (created) {
        return (
            <section className="carrierReviewCard carrierReviewCard--done" aria-labelledby={`${id}DoneHeading`}>
                <h3 className="carrierReviewTitle" id={`${id}DoneHeading`}>
                    {t.success.heading}
                </h3>
                <div className="carrierReviewDoneRating">
                    <span className="carrierReviewDoneLabel">{t.success.yourRating}</span>
                    <StarDisplay rating={created.rating} label={t.starLabel(created.rating)} />
                </div>
                {created.body && <p className="carrierReviewDoneBody">{created.body}</p>}
            </section>
        );
    }

    function mapError(e: unknown): string {
        if (e instanceof ApiError) {
            if (e.status === 409 && e.code === "conflict") return t.errors.alreadyReviewed;
            if (e.status === 403) return t.errors.forbidden;
            if (e.status === 422) return t.errors.bodyTooLong;
        }
        return t.errors.generic;
    }

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        if (submitting) return;
        setError(null);

        if (rating < REVIEW_MIN_RATING || rating > REVIEW_MAX_RATING) {
            setRatingError(t.errors.ratingRequired);
            return;
        }
        if (body.length > REVIEW_BODY_MAX) {
            setError(t.errors.bodyTooLong);
            return;
        }
        setRatingError(null);

        setSubmitting(true);
        try {
            const review = await createShipmentReview(shipmentId, {
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
        <section className="carrierReviewCard" aria-labelledby={`${id}Heading`}>
            <header className="carrierReviewHeader">
                <h3 className="carrierReviewTitle" id={`${id}Heading`}>
                    {t.title}
                </h3>
                <p className="carrierReviewLead">{t.lead}</p>
            </header>

            <form className="carrierReviewForm" onSubmit={handleSubmit} noValidate aria-busy={submitting || undefined}>
                <fieldset
                    className="carrierReviewFieldset"
                    disabled={submitting}
                    role="radiogroup"
                    aria-labelledby={`${id}RatingLegend`}
                    aria-describedby={ratingError ? `${id}RatingError` : undefined}
                >
                    <legend className="carrierReviewLegend" id={`${id}RatingLegend`}>
                        {t.ratingLabel}
                    </legend>
                    <div className="carrierReviewStars">
                        {STARS.map((n) => (
                            <button
                                key={n}
                                type="button"
                                role="radio"
                                aria-checked={rating === n}
                                aria-label={t.starLabel(n)}
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
                        <p className="carrierReviewFieldError" id={`${id}RatingError`}>
                            {ratingError}
                        </p>
                    )}
                </fieldset>

                <label className="carrierReviewLabel" htmlFor={`${id}Body`}>
                    {t.bodyLabel}
                    <textarea
                        id={`${id}Body`}
                        className="carrierReviewTextarea"
                        value={body}
                        maxLength={REVIEW_BODY_MAX}
                        rows={4}
                        placeholder={t.bodyPlaceholder}
                        onChange={(e) => setBody(e.target.value)}
                        disabled={submitting}
                    />
                    <span className="carrierReviewCounter" aria-hidden="true">
                        {t.bodyCounter(body.length, REVIEW_BODY_MAX)}
                    </span>
                </label>

                {error && (
                    <div className="carrierReviewError" role="alert">
                        {error}
                    </div>
                )}

                <div className="carrierReviewActions">
                    <Button variant="primary" size="default" type="submit" disabled={submitting}>
                        {submitting ? t.submitLoading : t.submit}
                    </Button>
                </div>
            </form>
        </section>
    );
}
