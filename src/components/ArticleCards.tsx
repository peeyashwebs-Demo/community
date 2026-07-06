import Link from "next/link";
import type { Article } from "@/types/database";

function readTime(body: string) {
  const words = body.replace(/<[^>]+>/g, " ").trim().split(/\s+/).length;
  return Math.max(1, Math.round(words / 200));
}

function formatDate(iso: string | null) {
  if (!iso) return "";
  return new Date(iso).toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" });
}

export function FeaturedCard({ article }: { article: Article }) {
  return (
    <article>
      <div className="mono-label mb-3 text-signal">
        Featured{article.category ? ` · ${article.category.name}` : ""}
      </div>
      <Link href={`/article/${article.slug}`}>
        <div
          className="mb-5 aspect-video w-full rounded bg-cover bg-center"
          style={{
            backgroundImage: article.cover_image_url
              ? `url(${article.cover_image_url})`
              : "linear-gradient(135deg,#c9c2b2,#8b8471)",
          }}
        />
        <h1 className="mb-3 font-display text-3xl font-semibold leading-tight sm:text-4xl">
          {article.title}
        </h1>
      </Link>
      <div className="mono-label flex flex-wrap items-center gap-3">
        <span>By {article.author?.name ?? "Unknown"}</span>
        <span>·</span>
        <span>{readTime(article.body)} min read</span>
        <span>·</span>
        <span>{formatDate(article.published_at)}</span>
      </div>
    </article>
  );
}

export function LatestItem({ article }: { article: Article }) {
  return (
    <Link href={`/article/${article.slug}`} className="flex gap-4 border-b border-rule py-4">
      <div
        className="h-16 w-22 flex-shrink-0 rounded bg-cover bg-center"
        style={{
          width: 88,
          height: 64,
          backgroundImage: article.cover_image_url
            ? `url(${article.cover_image_url})`
            : "linear-gradient(135deg,#b8ae97,#726c5c)",
        }}
      />
      <div className="min-w-0">
        {article.category && (
          <span className="mb-1 block text-[10px] font-semibold text-signal">
            {article.category.name.toUpperCase()}
          </span>
        )}
        <h4 className="mb-1.5 font-display text-base font-medium leading-snug">{article.title}</h4>
        <div className="mono-label text-[10.5px]">
          {article.author?.name} · {readTime(article.body)} min read
        </div>
      </div>
    </Link>
  );
}

export function MostReadItem({ article, rank }: { article: Article; rank: number }) {
  return (
    <Link href={`/article/${article.slug}`} className="flex gap-4">
      <span className="font-mono text-3xl font-medium leading-none text-rule">
        {String(rank).padStart(2, "0")}
      </span>
      <div>
        <h4 className="mb-1.5 font-display text-[15.5px] font-medium leading-snug">{article.title}</h4>
        <div className="mono-label text-[10.5px]">{article.read_count.toLocaleString()} reads</div>
      </div>
    </Link>
  );
}
