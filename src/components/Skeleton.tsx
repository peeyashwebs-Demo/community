export function SkeletonLine({ className = "" }: { className?: string }) {
  return <div className={`skeleton h-4 ${className}`} />;
}

export function SkeletonBlock({ className = "" }: { className?: string }) {
  return <div className={`skeleton ${className}`} />;
}

export function SkeletonCircle({ className = "" }: { className?: string }) {
  return <div className={`skeleton rounded-full ${className}`} />;
}

export function SkeletonPill({ className = "" }: { className?: string }) {
  return <div className={`skeleton rounded-full ${className}`} />;
}

/** A row shaped like the writer dashboard / admin list items. */
export function SkeletonRow() {
  return (
    <div className="flex items-center justify-between gap-4 border-b border-rule py-5">
      <div className="min-w-0 flex-1 space-y-2.5">
        <SkeletonLine className="w-2/3" />
        <SkeletonLine className="w-1/3" />
      </div>
      <SkeletonPill className="h-6 w-20 flex-shrink-0" />
    </div>
  );
}

/** A card shaped like the featured/latest article cards. */
export function SkeletonArticleCard({ variant = "list" }: { variant?: "featured" | "list" }) {
  if (variant === "featured") {
    return (
      <div>
        <SkeletonLine className="mb-3 h-3 w-24" />
        <SkeletonBlock className="mb-5 aspect-video w-full" />
        <SkeletonLine className="mb-2 h-8 w-full" />
        <SkeletonLine className="mb-4 h-8 w-3/4" />
        <SkeletonLine className="h-3 w-1/2" />
      </div>
    );
  }
  return (
    <div className="flex gap-4 border-b border-rule py-4">
      <SkeletonBlock className="h-16 w-[88px] flex-shrink-0" />
      <div className="flex-1 space-y-2">
        <SkeletonLine className="h-3 w-16" />
        <SkeletonLine className="h-4 w-full" />
        <SkeletonLine className="h-3 w-1/2" />
      </div>
    </div>
  );
}
