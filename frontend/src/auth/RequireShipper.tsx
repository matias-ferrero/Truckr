import { type ReactNode } from "react";
import { Navigate } from "react-router-dom";
import { useCurrentUser } from "./useCurrentUser";
import Forbidden from "./Forbidden";

type Props = { children: ReactNode };

/**
 * Guards routes that require an authenticated Shipper. Parallel to
 * RequireCarrier. Anonymous visitors are bounced to /login; an authenticated
 * non-Shipper sees a visible 403 view (REQ-BE-00032 AC) instead of a silent
 * redirect, so the access denial is explicit.
 */
export default function RequireShipper({ children }: Props) {
    const { me, loading } = useCurrentUser();

    if (loading) return null;
    if (!me) return <Navigate to="/login" replace />;
    if (!me.roles.includes("shipper")) return <Forbidden />;

    return <>{children}</>;
}
