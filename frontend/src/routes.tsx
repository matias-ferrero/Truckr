import { lazy, Suspense } from "react";
import { BrowserRouter, Outlet, Route, Routes } from "react-router-dom";
import LandingPage from "./App";
import { AuthProvider } from "./auth/AuthContext";
import { Header } from "./components/Header";
import RequireCarrier from "./auth/RequireCarrier";
import RequireShipper from "./auth/RequireShipper";
import RequireAuth from "./auth/RequireAuth";
import { useCurrentUser } from "./auth/useCurrentUser";
import { DashboardPage } from "./pages/dashboard/DashboardPage";

const LoginPage = lazy(() => import("./auth/LoginPage").then((m) => ({ default: m.LoginPage })));
const RegisterPage = lazy(() => import("./auth/RegisterPage").then((m) => ({ default: m.RegisterPage })));
const ImpersonatePage = lazy(() => import("./auth/ImpersonatePage"));
const VehicleForm           = lazy(() => import("./pages/carrier/VehicleForm"));
const VehicleList           = lazy(() => import("./pages/carrier/VehicleList"));
const TransportWindowList   = lazy(() => import("./pages/carrier/TransportWindowList"));
const TransportWindowForm   = lazy(() => import("./pages/carrier/TransportWindowForm"));
const CarrierCargoOfferInbox = lazy(() => import("./pages/carrier/CarrierCargoOfferInbox"));
const CarrierShipments = lazy(() => import("./pages/carrier/CarrierShipments"));
const ShipmentDetailPage = lazy(() => import("./pages/shipments/ShipmentDetailPage"));
const CarrierDetail = lazy(() => import("./pages/public/CarrierDetail"));
const CarrierMeRedirect = lazy(() => import("./pages/public/CarrierMeRedirect"));
const CreateOfferPage = lazy(() => import("./pages/shipper/CreateOfferPage"));
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

function CarrierLayout() {
    return (
        <RequireCarrier>
            <div className="carrierPage">
                <a className="skipLink" href="#main">Saltar al contenido</a>
                <Header />
                <Suspense fallback={<main className="carrierMain" id="main" aria-busy="true" />}>
                    <Outlet />
                </Suspense>
            </div>
        </RequireCarrier>
    );
}

function ShipperLayout() {
    return (
        <RequireShipper>
            <div className="shipperPage">
                <a className="skipLink" href="#main">Saltar al contenido</a>
                <Header />
                <Suspense fallback={<main className="shipperMain" id="main" aria-busy="true" />}>
                    <Outlet />
                </Suspense>
            </div>
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
        return (
            <div className="dashboardPage">
                <a className="skipLink" href="#main">Saltar al contenido</a>
                <Header />
                <Suspense fallback={<main className="dashboardMain" id="main" aria-busy="true" />}>
                    <DashboardPage />
                </Suspense>
            </div>
        );
    }

    return <LandingPage />;
}

export function AppRoutes() {
    return (
        <BrowserRouter>
            <AuthProvider>
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
                    </Route>
                    <Route element={<PublicLayout />}>
                        {/* Declared before `:id` so the literal segment wins over the wildcard. */}
                        <Route path="/carriers/me" element={<CarrierMeRedirect />} />
                        <Route path="/carriers/:id" element={<CarrierDetail />} />
                    </Route>
                    {/* US27 + US17 — Shipper flows under a shared layout. */}
                    <Route path="/shipper" element={<ShipperLayout />}>
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
            </AuthProvider>
        </BrowserRouter>
    );
}
