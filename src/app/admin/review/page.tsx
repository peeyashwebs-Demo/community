import { createClient } from "@/lib/supabase/server";
import { ReviewQueueItem } from "@/components/ReviewQueueItem";
import type { Article } from "@/types/database";

export const dynamic = "force-dynamic";

export default async function ReviewQueuePage() {
  const supabase = createClient();

  const { data } = await supabase
    .from("articles")
    .select("*, author:profiles(*)")
    .eq("status", "in_review")
    .order("created_at", { ascending: true });

  const articles = (data ?? []) as unknown as Article[];

  if (articles.length === 0) {
    return (
      <div className="rounded border border-dashed border-rule p-12 text-center">
        <p className="font-display text-lg font-medium">Queue is empty</p>
        <p className="mt-1 font-body italic text-ink-muted">Nothing waiting on a decision right now.</p>
      </div>
    );
  }

  return <div>{articles.map((a) => <ReviewQueueItem key={a.id} article={a} />)}</div>;
}
