import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { FeaturedCard, LatestItem, MostReadItem } from "@/components/ArticleCards";
import { HomeHero } from "@/components/HomeHero";
import { RevealSection } from "@/components/RevealSection";
import type { Article, Category } from "@/types/database";

export const dynamic = "force-dynamic";

const ARTICLE_SELECT = "*, author:profiles(*), category:categories(*)";

export default async function HomePage() {
  const supabase = createClient();

  const [{ data: latest }, { data: mostRead }, { data: categories }, { count: storyCount }, { count: writerCount }] =
    await Promise.all([
      supabase
        .from("articles")
        .select(ARTICLE_SELECT)
        .eq("status", "published")
        .order("published_at", { ascending: false })
        .limit(5),
      supabase
        .from("articles")
        .select(ARTICLE_SELECT)
        .eq("status", "published")
        .order("read_count", { ascending: false })
        .limit(3),
      supabase.from("categories").select("*").order("name"),
      supabase.from("articles").select("*", { count: "exact", head: true }).eq("status", "published"),
      supabase.from("profiles").select("*", { count: "exact", head: true }).in("role", ["writer", "editor"]),
    ]);

  const articles = (latest ?? []) as unknown as Article[];
  const featured = articles[0];
  const rest = articles.slice(1);
  const topRead = (mostRead ?? []) as unknown as Article[];
  const cats = (categories ?? []) as Category[];

  return (
    <>
      <HomeHero storyCount={storyCount ?? 0} writerCount={writerCount ?? 0} />

      <main id="feed" className="mx-auto max-w-6xl px-6 py-10 sm:px-10">
        {!featured ? (
          <div className="py-20 text-center">
            <p className="mono-label mb-3">No stories yet</p>
            <h1 className="font-display text-3xl font-semibold">
              The newsroom is quiet — for now.
            </h1>
            <p className="mt-3 font-body italic text-ink-muted">
              Once a writer publishes and an editor approves a story, it'll appear here.
            </p>
          </div>
        ) : (
          <>
            <div className="mb-10 flex flex-wrap gap-2.5">
              <span className="rounded-full bg-ink px-3.5 py-1.5 text-[12.5px] font-medium text-paper">
                All stories
              </span>
              {cats.map((c) => (
                <Link
                  key={c.id}
                  href={`/category/${c.slug}`}
                  className="rounded-full border border-rule px-3.5 py-1.5 text-[12.5px] font-medium text-ink-muted transition-colors hover:border-ink hover:text-ink"
                >
                  {c.name}
                </Link>
              ))}
            </div>

            <RevealSection className="mb-14 grid gap-12 lg:grid-cols-[1.4fr_1fr]">
              <FeaturedCard article={featured} />
              <aside>
                <h3 className="mono-label mb-4 border-b border-rule pb-2.5">Latest</h3>
                {rest.map((a) => (
                  <LatestItem key={a.id} article={a} />
                ))}
              </aside>
            </RevealSection>

            {topRead.length > 0 && (
              <RevealSection delay={0.1} className="mb-14 border-y border-rule py-6">
                <h3 className="mono-label mb-5">Most read this week</h3>
                <div className="grid gap-8 sm:grid-cols-3">
                  {topRead.map((a, i) => (
                    <MostReadItem key={a.id} article={a} rank={i + 1} />
                  ))}
                </div>
              </RevealSection>
            )}
          </>
        )}
      </main>
    </>
  );
}
