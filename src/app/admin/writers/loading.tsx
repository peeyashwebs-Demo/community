import { SkeletonLine, SkeletonBlock } from "@/components/Skeleton";

export default function Loading() {
  return (
    <div className="border-t border-rule">
      {Array.from({ length: 6 }).map((_, i) => (
        <div key={i} className="flex items-center justify-between border-b border-rule py-4">
          <div className="space-y-2">
            <SkeletonLine className="h-4 w-32" />
            <SkeletonLine className="h-3 w-48" />
          </div>
          <SkeletonBlock className="h-9 w-28" />
        </div>
      ))}
    </div>
  );
}
