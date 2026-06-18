import { cargoMatchesContent } from "./cargoMatchesContent";

const t = cargoMatchesContent.pagination;

type Props = {
    page: number;
    pageCount: number;
    onPageChange: (page: number) => void;
};

/** Client-side pager over the filtered + sorted grid (US25). */
export default function MatchesPagination({ page, pageCount, onPageChange }: Props) {
    if (pageCount <= 1) return null;

    return (
        <nav className="matchesPagination" aria-label={t.navLabel}>
            <button
                type="button"
                className="button buttonGhost"
                disabled={page <= 1}
                onClick={() => onPageChange(page - 1)}
            >
                {t.prev}
            </button>
            <span className="matchesPageStatus" aria-live="polite">
                {t.pageStatus(page, pageCount)}
            </span>
            <button
                type="button"
                className="button buttonGhost"
                disabled={page >= pageCount}
                onClick={() => onPageChange(page + 1)}
            >
                {t.next}
            </button>
        </nav>
    );
}
