import { ReactNode } from "react";
import { Navigate } from "react-router-dom";
import { useCurrentUser } from "./useCurrentUser";

type Props = { children: ReactNode };

/**
 * Route guard for screens that require *any* authenticated user
 * (carrier or shipper). Used by /profile and any future "my account"
 * surfaces. Anonymous visitors are bounced to /login.
 *
 * Distinct from RequireCarrier, which additionally rejects shippers.
 */
export default function RequireAuth({ children }: Props) {
    const { me, loading } = useCurrentUser();

    if (loading) return null;
    if (!me) return <Navigate to="/login" replace />;

    return <>{children}</>;
}
