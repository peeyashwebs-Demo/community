import { SkeletonRow } from "@/components/Skeleton";

export default function Loading() {
  return (
    <div className="divide-y divide-rule border-y border-rule">
      {Array.from({ length: 4 }).map((_, i) => (
        <SkeletonRow key={i} />
      ))}
    </div>
  );
}
