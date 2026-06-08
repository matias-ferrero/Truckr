// @vitest-environment happy-dom
import { describe, expect, it, vi, beforeEach, afterEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import ImpersonatePage from "./ImpersonatePage";

let replaceSpy: ReturnType<typeof vi.fn>;

const renderAt = (entry: string) =>
    render(
        <MemoryRouter initialEntries={[entry]}>
            <Routes>
                <Route path="/impersonate" element={<ImpersonatePage />} />
            </Routes>
        </MemoryRouter>,
    );

beforeEach(() => {
    localStorage.clear();
    replaceSpy = vi.fn();
    vi.stubGlobal("location", { ...window.location, replace: replaceSpy });
});

afterEach(() => {
    vi.unstubAllGlobals();
});

describe("ImpersonatePage", () => {
    it("stores the token from the URL fragment and hard-reloads to /", async () => {
        renderAt("/impersonate#token=header.payload.signature");

        await waitFor(() => {
            expect(window.localStorage.getItem("truckr.jwt")).toBe("header.payload.signature");
        });
        expect(replaceSpy).toHaveBeenCalledWith("/");
    });

    it("shows an error and does not store anything when the fragment is missing", async () => {
        renderAt("/impersonate");

        expect(await screen.findByText(/impersonation failed/i)).toBeInTheDocument();
        expect(window.localStorage.getItem("truckr.jwt")).toBeNull();
        expect(replaceSpy).not.toHaveBeenCalled();
    });

    it("rejects a malformed token (no dots) instead of storing it", async () => {
        renderAt("/impersonate#token=not-a-jwt");

        expect(await screen.findByText(/impersonation failed/i)).toBeInTheDocument();
        expect(window.localStorage.getItem("truckr.jwt")).toBeNull();
        expect(replaceSpy).not.toHaveBeenCalled();
    });
});
