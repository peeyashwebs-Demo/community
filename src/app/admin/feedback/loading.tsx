import { SkeletonLine } from "@/components/Skeleton";

export default function Loading() {
  return (
    <div className="divide-y divide-rule border-y border-rule">
      {Array.from({ length: 4 }).map((_, i) => (
        <div key={i} className="py-5">
          <div className="mb-2 flex items-center justify-between">
            <SkeletonLine className="h-4 w-28" />
            <SkeletonLine className="h-4 w-20" />
          </div>
          <SkeletonLine className="mb-2 h-4 w-full" />
          <SkeletonLine className="h-3 w-40" />
        </div>
      ))}
    </div>
  );
}
