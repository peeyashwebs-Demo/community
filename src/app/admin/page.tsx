import { createClient } from "@/lib/supabase/server";
import { attachAuthors } from "@/lib/relations";
import type { Article } from "@/types/database";

export const dynamic = "force-dynamic";

export default async function AdminDashboard() {
  const supabase = createClient();
  const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();

  const [{ count: publishedThisWeek }, { count: pendingCount }, { data: topStoriesRaw }] =
    await Promise.all([
      supabase
        .from("articles")
        .select("*", { count: "exact", head: true })
        .eq("status", "published")
        .gte("published_at", weekAgo),
      supabase
        .from("articles")
        .select("*", { count: "exact", head: true })
        .eq("status", "in_review"),
      supabase
        .from("articles")
        .select("*")
        .eq("status", "published")
        .order("read_count", { ascending: false })
        .limit(5),
    ]);

  const top = await attachAuthors(supabase, (topStoriesRaw ?? []) as Article[]);

  return (
    <div>
      <div className="mb-12 grid gap-6 sm:grid-cols-3">
        <div className="rounded border border-rule bg-surface p-6">
          <p className="mono-label mb-2">Published this week</p>
          <p className="font-display text-4xl font-semibold">{publishedThisWeek ?? 0}</p>
        </div>
        <div className="rounded border border-pending/30 bg-surface p-6">
          <p className="mono-label mb-2 text-pending">Pending review</p>
          <p className="font-display text-4xl font-semibold text-pending">{pendingCount ?? 0}</p>
        </div>
        <a href="/admin/review" className="flex flex-col justify-center rounded bg-signal p-6 text-white">
          <p className="mono-label mb-1 text-white/80">Next step</p>
          <p className="font-display text-xl font-semibold">Open the review queue →</p>
        </a>
      </div>

      <h2 className="mb-4 font-display text-xl font-semibold">Top stories by reads</h2>
      <div className="divide-y divide-rule border-y border-rule">
        {top.map((a, i) => (
          <div key={a.id} className="flex items-center justify-between py-4">
            <div className="flex items-center gap-4">
              <span className="font-mono text-2xl text-rule">{String(i + 1).padStart(2, "0")}</span>
              <div>
                <p className="font-display font-medium">{a.title}</p>
                <p className="mono-label">{a.author?.name}</p>
              </div>
            </div>
            <span className="mono-label">{a.read_count.toLocaleString()} reads</span>
          </div>
        ))}
      </div>
    </div>
  );
}
