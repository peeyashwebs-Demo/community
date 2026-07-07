import { SkeletonLine, SkeletonBlock } from "@/components/Skeleton";

export default function Loading() {
  return (
    <div className="border-t border-rule">
      {Array.from({ length: 5 }).map((_, i) => (
        <div key={i} className="border-b border-rule py-4">
          <SkeletonLine className="mb-2 h-3 w-32" />
          <SkeletonLine className="mb-3 h-4 w-full" />
          <div className="flex gap-2">
            <SkeletonBlock className="h-8 w-16" />
            <SkeletonBlock className="h-8 w-16" />
            <SkeletonBlock className="h-8 w-28" />
          </div>
        </div>
      ))}
    </div>
  );
}
