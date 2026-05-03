import { http, HttpResponse } from "msw";
import { API_BASE_URL } from "../../api";
import { landingContent } from "../../landingContent";

export const handlers = [
    http.get(`${API_BASE_URL}/api/landing_pages`, () => {
        return HttpResponse.json(landingContent);
    }),
];
