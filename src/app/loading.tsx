import { SkeletonArticleCard, SkeletonLine, SkeletonPill } from "@/components/Skeleton";

export default function Loading() {
  return (
    <>
      <div className="skeleton h-[88vh] min-h-[560px] w-full rounded-none" />

      <main className="mx-auto max-w-6xl px-6 py-10 sm:px-10">
        <div className="mb-10 flex flex-wrap gap-2.5">
          {Array.from({ length: 6 }).map((_, i) => (
            <SkeletonPill key={i} className="h-8 w-24" />
          ))}
        </div>

        <div className="mb-14 grid gap-12 lg:grid-cols-[1.4fr_1fr]">
          <SkeletonArticleCard variant="featured" />
          <aside>
            <SkeletonLine className="mb-4 h-3 w-20" />
            {Array.from({ length: 4 }).map((_, i) => (
              <SkeletonArticleCard key={i} />
            ))}
          </aside>
        </div>
      </main>
    </>
  );
}
