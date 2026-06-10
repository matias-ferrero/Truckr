import { useCallback, useEffect, useRef, useState } from "react";
import { Button } from "../../../components/ui/button";
import { useCurrentUser } from "../../../auth/useCurrentUser";
import {
    acceptCarrierCargoOffer,
    type CarrierCargoOffer,
    listCarrierCargoOffers,
    rejectCarrierCargoOffer,
} from "../../../api/carrierCargoOffers";
import { type CarrierActivityEvent, listCarrierActivity, listCarrierShipments } from "../../../api/shipments";
import type { Shipment } from "../../../api/shipments";
import { listMyVehicles } from "../../../api/vehicles";
import { listMyTransportWindows } from "../../../api/transport_windows";
import {
    buildCarrierDashboardModel,
    type CarrierSupply,
    type OfferCard as OfferCardModel,
} from "./buildCarrierDashboardModel";
import { buildCarrierActivityFeed } from "./buildCarrierActivityFeed";
import { carrierDashboardContent as t } from "./carrierDashboardContent";
import { CarrierDashboardGreeting } from "./CarrierDashboardGreeting";
import { CarrierStatsStrip } from "./CarrierStatsStrip";
import { CarrierAttentionPanel } from "./CarrierAttentionPanel";
import { JobBoard } from "./JobBoard";
import { CarrierActivityFeed } from "./CarrierActivityFeed";
import "../../../styles/carrierDashboard.css";

type Loaded = {
    offers: CarrierCargoOffer[];
    shipments: Shipment[];
    supply: CarrierSupply;
    activity: CarrierActivityEvent[];
};

type PageState =
    | { status: "loading" }
    | { status: "ready"; data: Loaded }
    | { status: "error"; message: string };

type ConfirmAction = { kind: "accept" | "reject"; card: OfferCardModel };

export default function CarrierDashboardPage() {
    const { me } = useCurrentUser();
    const [state, setState] = useState<PageState>({ status: "loading" });
    const [confirmAction, setConfirmAction] = useState<ConfirmAction | null>(null);
    const [busyOfferId, setBusyOfferId] = useState<number | null>(null);
    const [feedback, setFeedback] = useState<string | null>(null);
    const dialogRef = useRef<HTMLDialogElement>(null);

    // The carrier's own rating rides on the /me payload (CarrierResource).
    const ratingAvg =
        (me?.carrier as { rating_avg?: string | null } | undefined)?.rating_avg ?? null;

    const load = useCallback(async () => {
        setState({ status: "loading" });
        try {
            // The activity feed must never blank the dashboard: isolate its
            // failure so the board + attention panel still render.
            const activityPromise = listCarrierActivity().catch(
                () => [] as CarrierActivityEvent[],
            );
            const [offerResult, shipments, vehicles, windows, activity] = await Promise.all([
                listCarrierCargoOffers("pending"),
                listCarrierShipments(),
                listMyVehicles(),
                listMyTransportWindows(),
                activityPromise,
            ]);
            setState({
                status: "ready",
                data: {
                    offers: offerResult.items,
                    shipments,
                    supply: {
                        vehiclesCount: vehicles.meta.total,
                        openWindowsCount: windows.items.filter(
                            (w) => w.active && w.status === "open",
                        ).length,
                        ratingAvg: null, // re-derived below; supply is data-only here
                    },
                    activity,
                },
            });
        } catch (error) {
            setState({ status: "error", message: (error as Error).message });
        }
    }, []);

    useEffect(() => {
        load();
    }, [load]);

    useEffect(() => {
        const dialog = dialogRef.current;
        if (!dialog) return;
        if (confirmAction !== null) {
            dialog.showModal();
        } else if (dialog.open) {
            dialog.close();
        }
    }, [confirmAction]);

    async function confirmAndRun(): Promise<void> {
        if (!confirmAction) return;
        const { kind, card } = confirmAction;
        setConfirmAction(null);
        setBusyOfferId(card.offerId);
        setFeedback(null);
        try {
            if (kind === "accept") {
                await acceptCarrierCargoOffer(card.offerId);
                setFeedback(t.offerCard.accepted);
            } else {
                await rejectCarrierCargoOffer(card.offerId);
                setFeedback(t.offerCard.rejected);
            }
            await load();
        } catch (error) {
            setFeedback((error as Error).message || t.offerCard.actionError);
        } finally {
            setBusyOfferId(null);
        }
    }

    // First name for a warmer greeting; mirrors the shipper dashboard.
    const name = me ? (me.full_name || me.email).split(/[\s@]/)[0] || null : null;

    if (state.status === "loading") {
        return (
            <main className="page carrierMain dashPage dashPage--carrier" id="main">
                <div className="container">
                    <div
                        className="dashLoading"
                        role="status"
                        aria-busy="true"
                        aria-label={t.loadingLabel}
                    >
                        <div className="dashSkeleton dashSkeleton--greeting" />
                        <div className="dashSkeleton dashSkeleton--panel" />
                        <div className="dashSkeleton dashSkeleton--board" />
                    </div>
                </div>
            </main>
        );
    }

    if (state.status === "error") {
        return (
            <main className="page carrierMain dashPage dashPage--carrier" id="main">
                <div className="container">
                    <CarrierDashboardGreeting name={name} step="steady" />
                    <div className="dashErrorPanel" role="alert">
                        <p>{state.message || t.loadError}.</p>
                        <Button variant="primary" onClick={load}>{t.retry}</Button>
                    </div>
                </div>
            </main>
        );
    }

    const { offers, shipments, supply, activity } = state.data;
    const model = buildCarrierDashboardModel(offers, shipments, {
        ...supply,
        ratingAvg,
    });
    const feed = buildCarrierActivityFeed(activity);
    const isEmptyBoard = model.totalJobs === 0;
    const onboarding = t.onboarding[model.onboardingStep];

    return (
        <main className="page carrierMain dashPage dashPage--carrier" id="main">
            <div className="container">
                {feedback && (
                    <div className="savedBanner" role="status" aria-live="polite">
                        <span>{feedback}</span>
                        <button
                            className="savedBannerClose"
                            aria-label={t.offerCard.closeFeedback}
                            onClick={() => setFeedback(null)}
                        >
                            ×
                        </button>
                    </div>
                )}

                <CarrierDashboardGreeting name={name} step={model.onboardingStep} />

                {isEmptyBoard
                    ? (
                        <>
                            <section
                                className="dashOnboarding"
                                aria-labelledby="dash-onboarding-title"
                            >
                                <h2 className="dashOnboarding__title" id="dash-onboarding-title">
                                    {onboarding.title}
                                </h2>
                                <p className="dashOnboarding__lead">{onboarding.lead}</p>
                            </section>
                            <CarrierStatsStrip stats={model.stats} />
                        </>
                    )
                    : (
                        <>
                            <CarrierStatsStrip stats={model.stats} />
                            <CarrierAttentionPanel attention={model.attention} />
                            <JobBoard
                                model={model}
                                busyOfferId={busyOfferId}
                                onAccept={(card) => setConfirmAction({ kind: "accept", card })}
                                onReject={(card) => setConfirmAction({ kind: "reject", card })}
                            />
                            <CarrierActivityFeed items={feed} />
                        </>
                    )}
            </div>

            <dialog
                ref={dialogRef}
                className="confirmDialog"
                aria-labelledby="dash-confirm-title"
                aria-describedby="dash-confirm-desc"
                onClose={() => setConfirmAction(null)}
            >
                <div className="confirmDialogBody">
                    <h2 className="confirmDialogTitle" id="dash-confirm-title">
                        {confirmAction?.kind === "accept"
                            ? t.offerCard.confirm.acceptTitle
                            : t.offerCard.confirm.rejectTitle}
                    </h2>
                    <p className="confirmDialogText" id="dash-confirm-desc">
                        {confirmAction?.kind === "accept"
                            ? t.offerCard.confirm.acceptText
                            : t.offerCard.confirm.rejectText}
                    </p>
                    <div className="confirmDialogActions">
                        <Button variant="outline" onClick={() => setConfirmAction(null)}>
                            {t.offerCard.confirm.cancel}
                        </Button>
                        <Button
                            variant={confirmAction?.kind === "accept" ? "primary" : "danger"}
                            onClick={confirmAndRun}
                        >
                            {confirmAction?.kind === "accept"
                                ? t.offerCard.confirm.accept
                                : t.offerCard.confirm.reject}
                        </Button>
                    </div>
                </div>
            </dialog>
        </main>
    );
}
