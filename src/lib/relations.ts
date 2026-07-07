import type { SupabaseClient } from "@supabase/supabase-js";
import type { Profile, Category } from "@/types/database";

/**
 * Attaches `.author` to each row via a separate `profiles` query, instead of
 * relying on PostgREST's `author:profiles(*)` embed syntax. The embed syntax
 * depends on PostgREST having an up-to-date view of foreign-key
 * relationships in its schema cache — which can lag (sometimes for a long
 * time) after tables are created via raw SQL rather than through Supabase's
 * own migration tooling, or during platform-side incidents. Plain `.in()`
 * queries have no such dependency, so this is both a workaround and a more
 * robust long-term approach.
 */
export async function attachAuthors<T extends { author_id: string }>(
  supabase: SupabaseClient,
  rows: T[]
): Promise<(T & { author?: Profile })[]> {
  if (rows.length === 0) return rows as (T & { author?: Profile })[];

  const ids = [...new Set(rows.map((r) => r.author_id))];
  const { data } = await supabase.from("profiles").select("*").in("id", ids);
  const byId = Object.fromEntries(((data ?? []) as Profile[]).map((p) => [p.id, p]));

  return rows.map((r) => ({ ...r, author: byId[r.author_id] }));
}

/**
 * Same idea as attachAuthors, for `.category`.
 */
export async function attachCategories<T extends { category_id: string | null }>(
  supabase: SupabaseClient,
  rows: T[]
): Promise<(T & { category?: Category })[]> {
  const ids = [...new Set(rows.map((r) => r.category_id).filter((id): id is string => !!id))];

  if (ids.length === 0) {
    return rows.map((r) => ({ ...r, category: undefined }));
  }

  const { data } = await supabase.from("categories").select("*").in("id", ids);
  const byId = Object.fromEntries(((data ?? []) as Category[]).map((c) => [c.id, c]));

  return rows.map((r) => ({ ...r, category: r.category_id ? byId[r.category_id] : undefined }));
}
