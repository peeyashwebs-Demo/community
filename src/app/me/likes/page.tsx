import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { attachAuthors, attachCategories } from "@/lib/relations";
import { LatestItem } from "@/components/ArticleCards";
import type { Article } from "@/types/database";

export const dynamic = "force-dynamic";

export default async function LikedStoriesPage() {
  const supabase = createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect("/login?redirectTo=/me/likes");

  const { data: likeRows } = await supabase
    .from("likes")
    .select("article_id")
    .eq("user_id", user.id)
    .order("created_at", { ascending: false });

  const articleIds = (likeRows ?? []).map((r) => r.article_id);

  let articles: Article[] = [];
  if (articleIds.length > 0) {
    const { data: articlesRaw } = await supabase
      .from("articles")
      .select("*")
      .in("id", articleIds)
      .eq("status", "published");

    const withAuthors = await attachAuthors(supabase, (articlesRaw ?? []) as Article[]);
    articles = await attachCategories(supabase, withAuthors);

    // Preserve like-order (most recently liked first) since the .in() query doesn't guarantee it.
    const orderIndex = Object.fromEntries(articleIds.map((id, i) => [id, i]));
    articles.sort((a, b) => orderIndex[a.id] - orderIndex[b.id]);
  }

  return (
    <main className="mx-auto max-w-3xl px-6 py-10 sm:px-10">
      <p className="mono-label mb-2 text-signal">Your account</p>
      <h1 className="mb-10 font-display text-4xl font-semibold">Liked stories</h1>

      {articles.length === 0 ? (
        <div className="rounded border border-dashed border-rule p-12 text-center">
          <p className="mb-2 font-display text-lg font-medium">Nothing here yet</p>
          <p className="font-body italic text-ink-muted">
            Tap the heart on any story to save it here.
          </p>
        </div>
      ) : (
        <div>
          {articles.map((a) => (
            <LatestItem key={a.id} article={a} />
          ))}
        </div>
      )}
    </main>
  );
}
