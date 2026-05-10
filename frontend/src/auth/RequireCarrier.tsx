import { ReactNode } from "react";
import { Navigate } from "react-router-dom";
import { useCurrentUser } from "./useCurrentUser";

type Props = { children: ReactNode };

export default function RequireCarrier({ children }: Props) {
    const { me, loading } = useCurrentUser();

    if (loading) return null;
    if (!me) return <Navigate to="/login" replace />;
    if (!me.roles.includes("carrier")) return <Navigate to="/" replace />;

    return <>{children}</>;
}
