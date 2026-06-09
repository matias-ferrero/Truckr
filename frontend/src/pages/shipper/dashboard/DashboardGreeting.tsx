import { Link } from "react-router-dom";
import { buttonVariants } from "../../../components/ui/button";
import { shipperDashboardContent as t } from "./shipperDashboardContent";

export function DashboardGreeting({ name }: { name: string | null }) {
    const heading = name ? t.greeting(name) : t.greetingFallback;
    return (
        <header className="dashGreeting">
            <div className="dashGreeting__text">
                <h1 className="dashGreeting__title">{heading}</h1>
                <p className="dashGreeting__lead">{t.greetingLead}</p>
            </div>
            <Link
                to="/shipper/cargos/new"
                className={`dashGreeting__cta ${buttonVariants({ variant: "primary" })}`}
            >
                {t.publishCta}
            </Link>
        </header>
    );
}
