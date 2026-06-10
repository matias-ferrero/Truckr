import { Link } from "react-router-dom";
import { buttonVariants } from "../../../components/ui/button";
import type { OnboardingStep } from "./buildCarrierDashboardModel";
import { carrierDashboardContent as t } from "./carrierDashboardContent";

/** Greeting + the progressive primary CTA: the label and target follow the
 *  carrier's setup ladder (no vehicle → no window → steady). */
export function CarrierDashboardGreeting(
    { name, step }: { name: string | null; step: OnboardingStep },
) {
    const heading = name ? t.greeting(name) : t.greetingFallback;
    return (
        <header className="dashGreeting">
            <div className="dashGreeting__text">
                <h1 className="dashGreeting__title">{heading}</h1>
                <p className="dashGreeting__lead">{t.greetingLead}</p>
            </div>
            <Link
                to={t.ctaHref[step]}
                className={`dashGreeting__cta ${buttonVariants({ variant: "primary" })}`}
            >
                {t.cta[step]}
            </Link>
        </header>
    );
}
