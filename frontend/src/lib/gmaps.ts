import { Loader } from "@googlemaps/js-api-loader";

// `@googlemaps/js-api-loader` enforces a process-wide singleton keyed on the
// script id and throws if any later `new Loader()` differs on options
// (including `libraries`). All map-bearing components must share this loader
// so the union of required libraries is requested exactly once.
const LIBRARIES = ["places", "maps"] as const;

let cached: Loader | undefined;

export function getGoogleMapsLoader(apiKey: string): Loader {
    if (!cached) {
        cached = new Loader({
            apiKey,
            libraries: [...LIBRARIES],
            version:   "weekly",
        });
    }
    return cached;
}
