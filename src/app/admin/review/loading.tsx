import { SkeletonBlock, SkeletonLine } from "@/components/Skeleton";

export default function Loading() {
  return (
    <div>
      {Array.from({ length: 3 }).map((_, i) => (
        <div key={i} className="flex items-start justify-between gap-6 border-b border-rule py-6">
          <div className="flex-1 space-y-2.5">
            <SkeletonLine className="h-3 w-24" />
            <SkeletonLine className="h-6 w-2/3" />
            <SkeletonLine className="h-3 w-28" />
          </div>
          <div className="flex flex-col gap-2">
            <SkeletonBlock className="h-9 w-28" />
            <SkeletonBlock className="h-9 w-28" />
            <SkeletonBlock className="h-9 w-28" />
          </div>
        </div>
      ))}
    </div>
  );
}
