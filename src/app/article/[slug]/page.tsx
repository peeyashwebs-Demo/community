import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { CommentForm } from "@/components/CommentForm";
import { LikeButton } from "@/components/LikeButton";
import { RevealSection } from "@/components/RevealSection";
import type { Article, Comment } from "@/types/database";

export const dynamic = "force-dynamic";

function readTime(body: string) {
  const words = body.replace(/<[^>]+>/g, " ").trim().split(/\s+/).length;
  return Math.max(1, Math.round(words / 200));
}

function formatDate(iso: string | null) {
  if (!iso) return "";
  return new Date(iso).toLocaleDateString("en-US", { month: "long", day: "numeric", year: "numeric" });
}

export default async function ArticlePage({ params }: { params: { slug: string } }) {
  const supabase = createClient();

  const { data: article } = await supabase
    .from("articles")
    .select("*, author:profiles(*), category:categories(*)")
    .eq("slug", params.slug)
    .eq("status", "published")
    .single();

  if (!article) notFound();
  const a = article as unknown as Article;

  // Fire-and-forget atomic increment — doesn't block the render.
  supabase.rpc("increment_read_count", { article_slug: params.slug }).then(() => {});

  const {
    data: { user },
  } = await supabase.auth.getUser();

  const [{ data: comments }, { data: likeRow }] = await Promise.all([
    supabase
      .from("comments")
      .select("*, author:profiles(*)")
      .eq("article_id", a.id)
      .eq("status", "visible")
      .order("created_at", { ascending: true }),
    user
      ? supabase.from("likes").select("article_id").eq("article_id", a.id).eq("user_id", user.id).maybeSingle()
      : Promise.resolve({ data: null }),
  ]);

  const commentList = (comments ?? []) as unknown as Comment[];

  return (
    <main className="mx-auto max-w-article px-6 py-10 sm:px-0">
      {a.category && (
        <a href={`/category/${a.category.slug}`} className="mono-label mb-4 block text-signal">
          {a.category.name}
        </a>
      )}

      <h1 className="mb-5 font-display text-4xl font-semibold leading-tight sm:text-5xl">
        {a.title}
      </h1>

      <div className="mono-label mb-8 flex flex-wrap items-center gap-3">
        <span>By {a.author?.name ?? "Unknown"}</span>
        <span>·</span>
        <span>{readTime(a.body)} min read</span>
        <span>·</span>
        <span>{formatDate(a.published_at)}</span>
      </div>

      <div className="mb-8">
        <LikeButton
          articleId={a.id}
          initialCount={a.like_count}
          initiallyLiked={!!likeRow}
          isSignedIn={!!user}
        />
      </div>

      {a.cover_image_url && (
        <img
          src={a.cover_image_url}
          alt=""
          className="mb-10 aspect-video w-full rounded object-cover"
        />
      )}

      <div className="prose-article" dangerouslySetInnerHTML={{ __html: a.body }} />

      <hr className="my-12 border-rule" />

      <RevealSection>
        <h2 className="mb-6 font-display text-xl font-semibold">
          {commentList.length} {commentList.length === 1 ? "Comment" : "Comments"}
        </h2>

        <CommentForm articleId={a.id} isSignedIn={!!user} />

        <div className="space-y-6">
          {commentList.map((c) => (
            <div key={c.id} className="border-b border-rule pb-6">
              <div className="mono-label mb-2">
                {c.author?.name ?? "Reader"} · {formatDate(c.created_at)}
              </div>
              <p className="text-[15px] leading-relaxed">{c.body}</p>
            </div>
          ))}
        </div>
      </RevealSection>
    </main>
  );
}
