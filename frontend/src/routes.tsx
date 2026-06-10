import { lazy, Suspense } from "react";
import { BrowserRouter, Navigate, Outlet, Route, Routes } from "react-router-dom";
import LandingPage from "./App";
import { AuthProvider } from "./auth/AuthContext";
import { NotificationsProvider } from "./components/notifications/NotificationsProvider";
import { Header } from "./components/Header";
import { Sidebar } from "./components/Sidebar";
import RequireCarrier from "./auth/RequireCarrier";
import RequireShipper from "./auth/RequireShipper";
import RequireAuth from "./auth/RequireAuth";
import { useCurrentUser } from "./auth/useCurrentUser";

const LoginPage = lazy(() => import("./auth/LoginPage").then((m) => ({ default: m.LoginPage })));
const RegisterPage = lazy(() => import("./auth/RegisterPage").then((m) => ({ default: m.RegisterPage })));
const ImpersonatePage = lazy(() => import("./auth/ImpersonatePage"));
const VehicleForm           = lazy(() => import("./pages/carrier/VehicleForm"));
const VehicleList           = lazy(() => import("./pages/carrier/VehicleList"));
const TransportWindowList   = lazy(() => import("./pages/carrier/TransportWindowList"));
const TransportWindowForm   = lazy(() => import("./pages/carrier/TransportWindowForm"));
const CarrierCargoOfferInbox = lazy(() => import("./pages/carrier/CarrierCargoOfferInbox"));
const CarrierDashboardPage = lazy(() => import("./pages/carrier/dashboard/CarrierDashboardPage"));
const CarrierShipments = lazy(() => import("./pages/carrier/CarrierShipments"));
const CarrierPayoutsPage = lazy(() => import("./pages/carrier/CarrierPayoutsPage").then((m) => ({ default: m.CarrierPayoutsPage })));
const ShipmentDetailPage = lazy(() => import("./pages/shipments/ShipmentDetailPage"));
const CarrierDetail = lazy(() => import("./pages/public/CarrierDetail"));
const CarrierMeRedirect = lazy(() => import("./pages/public/CarrierMeRedirect"));
const ShipperDetail = lazy(() => import("./pages/public/ShipperDetail"));
const ShipperMeRedirect = lazy(() => import("./pages/public/ShipperMeRedirect"));
const CreateOfferPage = lazy(() => import("./pages/shipper/CreateOfferPage"));
const ShipperDashboardPage = lazy(() => import("./pages/shipper/dashboard/ShipperDashboardPage"));
const ShipperShipmentsPage = lazy(() => import("./pages/shipper/ShipperShipmentsPage"));
const ShipperPaymentPage = lazy(() => import("./pages/shipper/ShipperPaymentPage"));
const ShipperPaymentSuccessPage = lazy(() => import("./pages/shipper/ShipperPaymentSuccessPage"));
const ProfilePage = lazy(() => import("./pages/profile/ProfilePage"));
const CargoList   = lazy(() => import("./features/cargo/CargoList"));
const CargoForm   = lazy(() => import("./features/cargo/CargoForm"));
const CargoDetail = lazy(() => import("./features/cargo/CargoDetail"));
const CargoMatches = lazy(() => import("./features/cargo/CargoMatches"));

function AuthShell({ children }: { children: React.ReactNode }) {
    return (
        <div className="authPage">
            <a className="skipLink" href="#main">Saltar al contenido</a>
            <Header />
            <Suspense fallback={<div className="authMain" id="main" aria-busy="true" />}>
                {children}
            </Suspense>
        </div>
    );
}

/**
 * Authenticated app shell: sticky Header on top, persistent role-based Sidebar
 * to the left, page content to the right. Used by every logged-in surface so
 * the sidebar is present on any page. `pageClass` carries the section voice
 * (carrier / shipper / dashboard) via its CSS variables; `mainClass` styles the
 * Suspense fallback's <main>.
 */
function AppShell(
    { pageClass, mainClass, children }: {
        pageClass: string;
        mainClass: string;
        children: React.ReactNode;
    },
) {
    return (
        <div className={pageClass}>
            <a className="skipLink" href="#main">Saltar al contenido</a>
            <Header />
            <div className="appShellBody">
                <Sidebar />
                <Suspense fallback={<main className={mainClass} id="main" aria-busy="true" />}>
                    {children}
                </Suspense>
            </div>
        </div>
    );
}

function CarrierLayout() {
    return (
        <RequireCarrier>
            <AppShell pageClass="carrierPage" mainClass="carrierMain">
                <Outlet />
            </AppShell>
        </RequireCarrier>
    );
}

function ShipperLayout() {
    return (
        <RequireShipper>
            <AppShell pageClass="shipperPage" mainClass="shipperMain">
                <Outlet />
            </AppShell>
        </RequireShipper>
    );
}

function PublicLayout() {
    return (
        <div className="publicPage">
            <a className="skipLink" href="#main">Saltar al contenido</a>
            <Header />
            <Suspense fallback={<main className="publicMain" id="main" aria-busy="true" />}>
                <Outlet />
            </Suspense>
        </div>
    );
}

function IndexRoute() {
    const { me, loading } = useCurrentUser();
    if (loading) return null;

    if (me) {
        // Every carrier — including dual-role carrier+shipper — lands on the
        // job-funnel v2 dashboard; shippers land on the cargo-centric v2 one.
        // The old multi-section DashboardPage is retired as a landing.
        if (me.roles.includes("carrier")) {
            return <Navigate to="/carrier/dashboard" replace />;
        }
        if (me.roles.includes("shipper")) {
            return <Navigate to="/shipper/dashboard" replace />;
        }
        // A logged-in user with neither role (edge case) sees the public
        // landing; the old multi-section DashboardPage was retired.
    }

    return <LandingPage />;
}

export function AppRoutes() {
    return (
        <BrowserRouter>
            <AuthProvider>
                <NotificationsProvider>
                <Routes>
                    <Route path="/" element={<IndexRoute />} />
                    <Route
                        path="/login"
                        element={
                            <AuthShell>
                                <LoginPage />
                            </AuthShell>
                        }
                    />
                    <Route
                        path="/signup"
                        element={
                            <AuthShell>
                                <RegisterPage />
                            </AuthShell>
                        }
                    />
                    <Route
                        path="/impersonate"
                        element={
                            <Suspense fallback={<main aria-busy="true" />}>
                                <ImpersonatePage />
                            </Suspense>
                        }
                    />
                    <Route path="/carrier" element={<CarrierLayout />}>
                        <Route path="dashboard" element={<CarrierDashboardPage />} />
                        <Route path="vehicle" element={<VehicleForm mode="primary" />} />
                        <Route path="vehicle/new" element={<VehicleForm mode="new" />} />
                        <Route path="vehicle/:id" element={<VehicleForm mode="edit" />} />
                        <Route path="vehicles" element={<VehicleList />} />
                        <Route path="availability"     element={<TransportWindowList />} />
                        <Route path="availability/new" element={<TransportWindowForm mode="new" />} />
                        <Route path="availability/:id" element={<TransportWindowForm mode="edit" />} />
                        <Route path="cargo-offers" element={<CarrierCargoOfferInbox />} />
                        <Route path="shipments" element={<CarrierShipments />} />
                        <Route path="shipments/:id" element={<ShipmentDetailPage role="carrier" />} />
                        <Route path="payouts" element={<CarrierPayoutsPage />} />
                    </Route>
                    <Route element={<PublicLayout />}>
                        {/* Declared before `:id` so the literal segment wins over the wildcard. */}
                        <Route path="/carriers/me" element={<CarrierMeRedirect />} />
                        <Route path="/carriers/:id" element={<CarrierDetail />} />
                        {/* Declared before `:id` so the literal segment wins over the wildcard. */}
                        <Route path="/shippers/me" element={<ShipperMeRedirect />} />
                        <Route path="/shippers/:id" element={<ShipperDetail />} />
                    </Route>
                    {/* US27 + US17 — Shipper flows under a shared layout. */}
                    <Route path="/shipper" element={<ShipperLayout />}>
                        <Route path="dashboard" element={<ShipperDashboardPage />} />
                        <Route path="cargos">
                            <Route index element={<CargoList />} />
                            <Route path="new" element={<CargoForm mode="new" />} />
                            <Route path=":id" element={<CargoDetail />} />
                            <Route path=":id/edit" element={<CargoForm mode="edit" />} />
                            <Route path=":id/matches" element={<CargoMatches />} />
                            <Route path=":id/offers/new" element={<CreateOfferPage />} />
                        </Route>
                        <Route path="shipments" element={<ShipperShipmentsPage />} />
                        <Route path="shipments/:id" element={<ShipmentDetailPage role="shipper" />} />
                        <Route path="shipments/:id/pay" element={<ShipperPaymentPage />} />
                        <Route path="shipments/:id/pay/success" element={<ShipperPaymentSuccessPage />} />
                    </Route>
                    <Route
                        path="/profile"
                        element={
                            <RequireAuth>
                                <AuthShell>
                                    <ProfilePage />
                                </AuthShell>
                            </RequireAuth>
                        }
                    />
                    <Route path="*" element={<IndexRoute />} />
                </Routes>
                </NotificationsProvider>
            </AuthProvider>
        </BrowserRouter>
    );
}
