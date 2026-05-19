import { type ReactNode } from "react";
import { Navigate } from "react-router-dom";
import { useCurrentUser } from "./useCurrentUser";

type Props = { children: ReactNode };

/** Guards routes that require an authenticated Shipper. Parallel to RequireCarrier. */
export default function RequireShipper({ children }: Props) {
    const { me, loading } = useCurrentUser();

    if (loading) return null;
    if (!me) return <Navigate to="/login" replace />;
    if (!me.roles.includes("shipper")) return <Navigate to="/" replace />;

    return <>{children}</>;
}
