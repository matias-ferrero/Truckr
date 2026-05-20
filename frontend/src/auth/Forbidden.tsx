import { Link } from "react-router-dom";
import { authContent } from "./authContent";

const t = authContent.forbidden;

/**
 * Visible 403 view shown when an authenticated user reaches a route their
 * role can't access (e.g. a Carrier hitting a Shipper-only screen). Replaces
 * the previous silent `<Navigate to="/" />` so the access denial is explicit
 * (REQ-BE-00032 AC — "non-Shipper sees a 403 view").
 */
export default function Forbidden() {
    return (
        <main className="page" id="main">
            <div className="container">
                <section className="forbiddenPanel" role="alert">
                    <p className="forbiddenCode" aria-hidden="true">
                        403
                    </p>
                    <h1 className="sectionTitle">{t.title}</h1>
                    <p className="sectionLead">{t.lead}</p>
                    <Link to="/" className="button buttonPrimary">
                        {t.backHome}
                    </Link>
                </section>
            </div>
        </main>
    );
}
