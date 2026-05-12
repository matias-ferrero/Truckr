import { Navigate } from "react-router-dom";
import { useCurrentUser } from "../../auth/useCurrentUser";

/**
 * Resolves /carriers/me to the authenticated user's public profile.
 *
 * - Loading → null (PublicLayout already renders a Suspense fallback).
 * - Not authenticated → /login.
 * - Authenticated but not a carrier → / (no public profile to show).
 * - Carrier → /carriers/:id (replace, so the back button skips this hop).
 */
export default function CarrierMeRedirect() {
    const { me, loading } = useCurrentUser();
    if (loading) return null;
    if (!me) return <Navigate to="/login" replace />;

    const carrierId = (me.carrier as { id?: number } | null | undefined)?.id;
    if (!carrierId) return <Navigate to="/" replace />;

    return <Navigate to={`/carriers/${carrierId}`} replace />;
}
