import React from "react";
import ReactDOM from "react-dom/client";
import { AppRoutes } from "./routes";
import "./styles/tailwind.css";
import "./styles/global.css";
import "./styles/landing.css";
import "./styles/auth.css";
import "./styles/carrier.css";
import "./styles/shipper.css";
import "./styles/public.css";

ReactDOM.createRoot(document.getElementById("root")!).render(
    <React.StrictMode>
        <AppRoutes />
    </React.StrictMode>
);
