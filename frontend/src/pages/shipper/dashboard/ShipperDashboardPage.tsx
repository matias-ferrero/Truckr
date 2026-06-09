import { useCallback, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { Button, buttonVariants } from "../../../components/ui/button";
import { useCurrentUser } from "../../../auth/useCurrentUser";
import { listCargos } from "../../../features/cargo/api";
import { listShipperActivity, listShipperShipments } from "../../../api/shipments";
import type { Cargo } from "../../../types/Cargo";
import type { Shipment, ShipperActivityEvent } from "../../../api/shipments";
import { buildDashboardModel } from "./buildDashboardModel";
import { buildActivityFeed } from "./buildActivityFeed";
import { shipperDashboardContent as t } from "./shipperDashboardContent";
import { DashboardGreeting } from "./DashboardGreeting";
import { AttentionPanel } from "./AttentionPanel";
import { CargoBoard } from "./CargoBoard";
import { ActivityFeed } from "./ActivityFeed";
import "../../../styles/shipperDashboard.css";

type Loaded = {
    cargos: Cargo[];
    shipments: Shipment[];
    activity: ShipperActivityEvent[];
};

type PageState =
    | { status: "loading" }
    | { status: "ready"; data: Loaded }
    | { status: "error"; message: string };

export default function ShipperDashboardPage() {
    const { me } = useCurrentUser();
    const [state, setState] = useState<PageState>({ status: "loading" });

    const load = useCallback(async () => {
        setState({ status: "loading" });
        try {
            // The activity feed must never blank the dashboard: isolate its
            // failure so the board + attention panel still render.
            const activityPromise = listShipperActivity().catch(
                () => [] as ShipperActivityEvent[],
            );
            const [cargoResult, shipments, activity] = await Promise.all([
                listCargos(),
                listShipperShipments(),
                activityPromise,
            ]);
            setState({
                status: "ready",
                data: { cargos: cargoResult.items, shipments, activity },
            });
        } catch (error) {
            setState({ status: "error", message: (error as Error).message });
        }
    }, []);

    useEffect(() => {
        load();
    }, [load]);

    // First name for a warmer greeting; mirrors the existing dashboard convention.
    const name = me ? (me.full_name || me.email).split(/[\s@]/)[0] || null : null;

    if (state.status === "loading") {
        return (
            <main className="page shipperMain dashPage" id="main">
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
            <main className="page shipperMain dashPage" id="main">
                <div className="container">
                    <DashboardGreeting name={name} />
                    <div className="dashErrorPanel" role="alert">
                        <p>{state.message || t.loadError}.</p>
                        <Button variant="primary" onClick={load}>{t.retry}</Button>
                    </div>
                </div>
            </main>
        );
    }

    const { cargos, shipments, activity } = state.data;
    const model = buildDashboardModel(cargos, shipments);
    const feed = buildActivityFeed(cargos, activity, shipments);
    const isNewShipper = model.totalCargos === 0 && shipments.length === 0;

    return (
        <main className="page shipperMain dashPage" id="main">
            <div className="container">
                <DashboardGreeting name={name} />

                {isNewShipper
                    ? (
                        <section className="dashOnboarding" aria-labelledby="dash-onboarding-title">
                            <h2 className="dashOnboarding__title" id="dash-onboarding-title">
                                {t.onboarding.title}
                            </h2>
                            <p className="dashOnboarding__lead">{t.onboarding.lead}</p>
                            <Link
                                to="/shipper/cargos/new"
                                className={buttonVariants({ variant: "primary" })}
                            >
                                {t.publishCta}
                            </Link>
                        </section>
                    )
                    : (
                        <>
                            <AttentionPanel attention={model.attention} />
                            <CargoBoard model={model} />
                            <ActivityFeed items={feed} />
                        </>
                    )}
            </div>
        </main>
    );
}
