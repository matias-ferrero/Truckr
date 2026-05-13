import { useParams, Link } from "react-router-dom";
import { carrierDetailContent as t } from "./carrierDetailContent";

export default function CarrierDetailPlaceholder() {
    const { id } = useParams();

    return (
        <main className="page carrierMain" id="main">
            <div className="container searchShell">
                <header className="searchHeader">
                    <h1 className="sectionTitle">{t.title}</h1>
                    <p className="sectionLead">
                        {t.lead(id)}
                    </p>
                </header>

                <section className="searchStatePanel" aria-live="polite">
                    <p>{t.body}</p>
                    <Link to="/transport_windows/search" className="button buttonPrimary">
                        {t.back}
                    </Link>
                </section>
            </div>
        </main>
    );
}
