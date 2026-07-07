import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { getProfile } from "@/lib/getProfile";
import { attachCategories } from "@/lib/relations";
import { StatusBadge } from "@/components/StatusBadge";
import type { Article } from "@/types/database";

export const dynamic = "force-dynamic";

export default async function WriterDashboard() {
  const profile = await getProfile();
  const supabase = createClient();

  const { data } = await supabase
    .from("articles")
    .select("*")
    .eq("author_id", profile!.id)
    .order("updated_at", { ascending: false });

  const articles = await attachCategories(supabase, (data ?? []) as Article[]);

  if (articles.length === 0) {
    return (
      <div className="rounded border border-dashed border-rule p-12 text-center">
        <p className="mb-2 font-display text-lg font-medium">Nothing here yet</p>
        <p className="mb-6 font-body italic text-ink-muted">
          Start your first draft — it autosaves as you write.
        </p>
        <Link href="/writer/new" className="btn-solid">
          Write your first story
        </Link>
      </div>
    );
  }

  return (
    <div className="divide-y divide-rule border-y border-rule">
      {articles.map((a) => (
        <Link
          key={a.id}
          href={`/writer/${a.id}/edit`}
          className="flex items-center justify-between gap-4 py-5"
        >
          <div className="min-w-0">
            <h3 className="mb-1.5 truncate font-display text-lg font-medium">
              {a.title || "Untitled draft"}
            </h3>
            <div className="mono-label flex flex-wrap gap-3">
              {a.category && <span>{a.category.name}</span>}
              <span>Updated {new Date(a.updated_at).toLocaleDateString()}</span>
              {a.status === "published" && <span>{a.read_count.toLocaleString()} reads</span>}
            </div>
            {a.status === "rejected" && a.review_note && (
              <p className="mt-2 max-w-lg text-sm text-danger">Editor feedback: {a.review_note}</p>
            )}
          </div>
          <StatusBadge status={a.status} />
        </Link>
      ))}
    </div>
  );
}
