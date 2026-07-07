import { SkeletonArticleCard, SkeletonLine } from "@/components/Skeleton";

export default function Loading() {
  return (
    <main className="mx-auto max-w-3xl px-6 py-10 sm:px-10">
      <SkeletonLine className="mb-2 h-3 w-20" />
      <SkeletonLine className="mb-10 h-10 w-48" />
      {Array.from({ length: 6 }).map((_, i) => (
        <SkeletonArticleCard key={i} />
      ))}
    </main>
  );
}
