import { SkeletonBlock, SkeletonLine } from "@/components/Skeleton";

export function MastheadSkeleton() {
  return (
    <header className="sticky top-0 z-20 border-b border-rule bg-paper">
      <div className="hidden border-b border-rule/60 px-6 py-2 sm:flex sm:px-10">
        <SkeletonLine className="h-3 w-32" />
      </div>
      <div className="flex items-center justify-between px-4 py-4 sm:px-10 sm:py-5">
        <SkeletonLine className="h-8 w-28" />
        <div className="hidden gap-7 lg:flex">
          {Array.from({ length: 5 }).map((_, i) => (
            <SkeletonLine key={i} className="h-4 w-16" />
          ))}
        </div>
        <div className="hidden items-center gap-3 lg:flex">
          <SkeletonBlock className="h-9 w-20" />
          <SkeletonBlock className="h-9 w-24" />
        </div>
        <SkeletonBlock className="h-9 w-9 lg:hidden" />
      </div>
    </header>
  );
}
