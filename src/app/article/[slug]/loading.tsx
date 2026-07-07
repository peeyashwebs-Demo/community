import { SkeletonBlock, SkeletonLine } from "@/components/Skeleton";

export default function Loading() {
  return (
    <main className="mx-auto max-w-article px-6 py-10 sm:px-0">
      <SkeletonLine className="mb-4 h-3 w-20" />
      <SkeletonLine className="mb-2 h-10 w-full" />
      <SkeletonLine className="mb-5 h-10 w-2/3" />
      <div className="mb-8 flex gap-3">
        <SkeletonLine className="h-3 w-24" />
        <SkeletonLine className="h-3 w-20" />
        <SkeletonLine className="h-3 w-28" />
      </div>
      <SkeletonBlock className="mb-8 h-9 w-32 rounded-full" />
      <SkeletonBlock className="mb-10 aspect-video w-full" />
      <div className="space-y-4">
        {Array.from({ length: 6 }).map((_, i) => (
          <SkeletonLine key={i} className="h-4 w-full" />
        ))}
        <SkeletonLine className="h-4 w-2/3" />
      </div>
    </main>
  );
}
