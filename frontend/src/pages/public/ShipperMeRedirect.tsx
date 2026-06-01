import { Navigate } from "react-router-dom";
import { useCurrentUser } from "../../auth/useCurrentUser";

/**
 * Resolves /shippers/me to the authenticated user's public profile.
 * Mirror of CarrierMeRedirect.
 *
 * - Loading → null (PublicLayout already renders a Suspense fallback).
 * - Not authenticated → /login.
 * - Authenticated but not a shipper → / (no public profile to show).
 * - Shipper → /shippers/:id (replace, so the back button skips this hop).
 */
export default function ShipperMeRedirect() {
    const { me, loading } = useCurrentUser();
    if (loading) return null;
    if (!me) return <Navigate to="/login" replace />;

    const shipperId = (me.shipper as { id?: number } | null | undefined)?.id;
    if (!shipperId) return <Navigate to="/" replace />;

    return <Navigate to={`/shippers/${shipperId}`} replace />;
}
