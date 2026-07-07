import { SkeletonBlock, SkeletonLine, SkeletonPill } from "@/components/Skeleton";

export default function Loading() {
  return (
    <div className="mx-auto max-w-3xl px-6 py-10 sm:px-10">
      <div className="mb-8 flex items-center justify-between">
        <SkeletonPill className="h-6 w-20" />
        <SkeletonLine className="h-3 w-12" />
      </div>
      <SkeletonLine className="mb-6 h-10 w-full" />
      <div className="mb-6 flex gap-4">
        <SkeletonBlock className="h-9 w-40" />
        <SkeletonBlock className="h-9 w-40" />
      </div>
      <SkeletonBlock className="h-80 w-full" />
    </div>
  );
}
