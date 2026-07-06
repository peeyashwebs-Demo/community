import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { ArticleEditor } from "@/components/ArticleEditor";
import type { Article, Category } from "@/types/database";

export const dynamic = "force-dynamic";

export default async function EditArticlePage({ params }: { params: { id: string } }) {
  const supabase = createClient();

  const [{ data: article }, { data: categories }] = await Promise.all([
    supabase.from("articles").select("*").eq("id", params.id).single(),
    supabase.from("categories").select("*").order("name"),
  ]);

  if (!article) notFound();

  return (
    <ArticleEditor
      article={article as unknown as Article}
      categories={(categories ?? []) as Category[]}
    />
  );
}
