import { lazy, Suspense } from "react";
import { BrowserRouter, Outlet, Route, Routes } from "react-router-dom";
import LandingPage from "./App";
import { AuthProvider } from "./auth/AuthContext";
import { Header } from "./components/Header";
import RequireCarrier from "./auth/RequireCarrier";
import { useCurrentUser } from "./auth/useCurrentUser";
import { DashboardPage } from "./pages/dashboard/DashboardPage";

const LoginPage = lazy(() => import("./auth/LoginPage").then((m) => ({ default: m.LoginPage })));
const RegisterPage = lazy(() => import("./auth/RegisterPage").then((m) => ({ default: m.RegisterPage })));
const CarrierSearchPage = lazy(() => import("./pages/search/CarrierSearchPage"));
const CarrierDetailPlaceholder = lazy(() => import("./pages/carriers/CarrierDetailPlaceholder"));
const VehicleForm = lazy(() => import("./pages/carrier/VehicleForm"));
const VehicleList = lazy(() => import("./pages/carrier/VehicleList"));
const CarrierDetail = lazy(() => import("./pages/public/CarrierDetail"));
const CarrierMeRedirect = lazy(() => import("./pages/public/CarrierMeRedirect"));

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
                        path="/transport_windows/search"
                        element={
                            <AuthShell>
                                <CarrierSearchPage />
                            </AuthShell>
                        }
                    />
                    <Route
                        path="/carriers/:id"
                        element={
                            <AuthShell>
                                <CarrierDetailPlaceholder />
                            </AuthShell>
                        }
                    />
                    <Route path="/carrier" element={<CarrierLayout />}>
                        <Route path="vehicle" element={<VehicleForm mode="primary" />} />
                        <Route path="vehicle/new" element={<VehicleForm mode="new" />} />
                        <Route path="vehicle/:id" element={<VehicleForm mode="edit" />} />
                        <Route path="vehicles" element={<VehicleList />} />
                    </Route>
                    <Route element={<PublicLayout />}>
                        {/* Declared before `:id` so the literal segment wins over the wildcard. */}
                        <Route path="/carriers/me" element={<CarrierMeRedirect />} />
                        <Route path="/carriers/:id" element={<CarrierDetail />} />
                    </Route>
                    <Route path="*" element={<IndexRoute />} />
                </Routes>
            </AuthProvider>
        </BrowserRouter>
    );
}
