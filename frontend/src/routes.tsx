import { lazy, Suspense } from "react";
import { BrowserRouter, Route, Routes } from "react-router-dom";
import LandingPage from "./App";
import { AuthProvider } from "./auth/AuthContext";
import { Header } from "./components/Header";

const LoginPage = lazy(() => import("./auth/LoginPage").then((m) => ({ default: m.LoginPage })));
const RegisterPage = lazy(() => import("./auth/RegisterPage").then((m) => ({ default: m.RegisterPage })));

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
                    <Route path="*" element={<LandingPage />} />
                </Routes>
            </AuthProvider>
        </BrowserRouter>
    );
}
