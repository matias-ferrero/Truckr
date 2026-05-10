import { useContext } from "react";
import { AuthContext } from "./AuthContext";

export function useCurrentUser() {
    const ctx = useContext(AuthContext);
    if (!ctx) throw new Error("useCurrentUser must be used inside <AuthProvider>");
    return ctx;
}
