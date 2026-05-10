import { lazy, Suspense } from "react";
import { BrowserRouter, Outlet, Route, Routes } from "react-router-dom";
import LandingPage from "./App";
import { AuthProvider } from "./auth/AuthContext";
import { Header } from "./components/Header";
import RequireCarrier from "./auth/RequireCarrier";

const LoginPage = lazy(() => import("./auth/LoginPage").then((m) => ({ default: m.LoginPage })));
const RegisterPage = lazy(() => import("./auth/RegisterPage").then((m) => ({ default: m.RegisterPage })));
const VehicleForm = lazy(() => import("./pages/carrier/VehicleForm"));
const VehicleList = lazy(() => import("./pages/carrier/VehicleList"));

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

export function AppRoutes() {
    return (
        <BrowserRouter>
            <AuthProvider>
                <Routes>
                    <Route path="/" element={<LandingPage />} />
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
                    <Route path="/carrier" element={<CarrierLayout />}>
                        <Route path="vehicle" element={<VehicleForm mode="primary" />} />
                        <Route path="vehicle/new" element={<VehicleForm mode="new" />} />
                        <Route path="vehicle/:id" element={<VehicleForm mode="edit" />} />
                        <Route path="vehicles" element={<VehicleList />} />
                    </Route>
                    <Route path="*" element={<LandingPage />} />
                </Routes>
            </AuthProvider>
        </BrowserRouter>
    );
}
