import { SkeletonBlock } from "@/components/Skeleton";

export default function Loading() {
  return (
    <div>
      <div className="mb-12 grid gap-6 sm:grid-cols-3">
        <SkeletonBlock className="h-28 w-full" />
        <SkeletonBlock className="h-28 w-full" />
        <SkeletonBlock className="h-28 w-full" />
      </div>
      <SkeletonBlock className="mb-4 h-6 w-48" />
      <div className="space-y-4 border-y border-rule py-4">
        {Array.from({ length: 5 }).map((_, i) => (
          <SkeletonBlock key={i} className="h-10 w-full" />
        ))}
      </div>
    </div>
  );
}
