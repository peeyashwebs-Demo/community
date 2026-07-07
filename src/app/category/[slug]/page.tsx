import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { attachAuthors, attachCategories } from "@/lib/relations";
import { LatestItem } from "@/components/ArticleCards";
import type { Article } from "@/types/database";

export const dynamic = "force-dynamic";

export default async function CategoryPage({ params }: { params: { slug: string } }) {
  const supabase = createClient();

  const { data: category } = await supabase
    .from("categories")
    .select("*")
    .eq("slug", params.slug)
    .single();

  if (!category) notFound();

  const { data: articlesRaw } = await supabase
    .from("articles")
    .select("*")
    .eq("status", "published")
    .eq("category_id", category.id)
    .order("published_at", { ascending: false });

  const withAuthors = await attachAuthors(supabase, (articlesRaw ?? []) as Article[]);
  const list = await attachCategories(supabase, withAuthors);

  return (
    <main className="mx-auto max-w-3xl px-6 py-10 sm:px-10">
      <p className="mono-label mb-2 text-signal">Category</p>
      <h1 className="mb-10 font-display text-4xl font-semibold">{category.name}</h1>

      {list.length === 0 ? (
        <p className="font-body italic text-ink-muted">No published stories in this category yet.</p>
      ) : (
        <div>
          {list.map((a) => (
            <LatestItem key={a.id} article={a} />
          ))}
        </div>
      )}
    </main>
  );
}
