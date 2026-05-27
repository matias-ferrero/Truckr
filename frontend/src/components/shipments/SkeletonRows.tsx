export function SkeletonRows() {
    return (
        <>
            {[0, 1, 2].map((i) => (
                <li key={i} className="shipmentRowSkeleton" aria-hidden="true">
                    <div className="shipmentRowMain">
                        <div className="skeletonHeadline">
                            <div className="skeletonLine skeletonLineRoute" />
                            <div className="skeletonLine skeletonLineAmount" />
                        </div>
                        <div className="skeletonSubline">
                            <div className="skeletonPill skeletonChipState" />
                            <div className="skeletonPill skeletonChipPayment" />
                            <div className="skeletonLine skeletonLineDate" />
                        </div>
                    </div>
                </li>
            ))}
        </>
    );
}
