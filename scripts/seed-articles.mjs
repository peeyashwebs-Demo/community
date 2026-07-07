/**
 * One-time seed script: creates 3 demo writer accounts and 60 published
 * articles (10 per category), using Supabase's official Admin API.
 *
 * Why this replaced the old SQL-based seed (0004_seed_articles.sql):
 * inserting rows directly into auth.users via raw SQL is fragile — Supabase's
 * internal auth schema has required columns that change across project
 * versions, and a mismatch there fails silently in the SQL editor. This
 * script uses supabase.auth.admin.createUser(), the same official path
 * Supabase itself uses, so it works regardless of your project's schema
 * version.
 *
 * Usage:
 *   1. Get your SERVICE ROLE key: Supabase dashboard → Project Settings → API
 *      → "service_role" key (NOT the anon/publishable one — this one is
 *      secret and bypasses RLS, never expose it in frontend code).
 *   2. Add it to .env.local as SUPABASE_SERVICE_ROLE_KEY=... (this variable
 *      name deliberately has no NEXT_PUBLIC_ prefix, so it never ships to
 *      the browser).
 *   3. Run:  node scripts/seed-articles.mjs
 */

import { createClient } from "@supabase/supabase-js";
import { readFileSync } from "fs";
import { fileURLToPath } from "url";
import { dirname, join } from "path";
import dotenv from "dotenv";

const __dirname = dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: join(__dirname, "..", ".env.local") });

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL;
const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
  console.error(
    "\nMissing env vars. Make sure .env.local has both:\n" +
      "  NEXT_PUBLIC_SUPABASE_URL=...\n" +
      "  SUPABASE_SERVICE_ROLE_KEY=...  (from Project Settings → API → service_role)\n"
  );
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const seedData = JSON.parse(readFileSync(join(__dirname, "seed-data.json"), "utf-8"));

async function main() {
  console.log(`Seeding ${seedData.writers.length} writers and ${seedData.articles.length} articles...\n`);

  // ---- Writers ----
  const writerIdByEmail = {};

  for (const writer of seedData.writers) {
    // Re-running this script is safe: if the user already exists, look it up
    // instead of erroring.
    const { data: created, error: createError } = await supabase.auth.admin.createUser({
      email: writer.email,
      password: "SeedWriter!2026",
      email_confirm: true,
      user_metadata: { name: writer.name },
    });

    let userId;
    if (createError) {
      if (createError.message?.toLowerCase().includes("already been registered")) {
        const { data: list } = await supabase.auth.admin.listUsers();
        const existing = list.users.find((u) => u.email === writer.email);
        userId = existing?.id;
        console.log(`  ${writer.name} already exists, reusing account.`);
      } else {
        console.error(`  Failed to create ${writer.name}:`, createError.message);
        continue;
      }
    } else {
      userId = created.user.id;
      console.log(`  Created ${writer.name} (${writer.email})`);
    }

    if (!userId) continue;

    const { error: roleError } = await supabase.from("profiles").update({ role: "writer" }).eq("id", userId);
    if (roleError) console.error(`  Couldn't set role for ${writer.name}:`, roleError.message);

    writerIdByEmail[writer.email] = userId;
  }

  // ---- Categories ----
  const { data: categories, error: catError } = await supabase.from("categories").select("id, slug");
  if (catError) {
    console.error("Couldn't load categories — did you run 0001_init.sql?", catError.message);
    process.exit(1);
  }
  const categoryIdBySlug = Object.fromEntries(categories.map((c) => [c.slug, c.id]));

  // ---- Articles ----
  let createdCount = 0;
  let skipped = 0;

  for (const article of seedData.articles) {
    const authorId = writerIdByEmail[article.author_email];
    const categoryId = categoryIdBySlug[article.category_slug];

    if (!authorId || !categoryId) {
      console.error(`  Skipping "${article.title}" — missing author or category.`);
      skipped++;
      continue;
    }

    const publishedAt = new Date(Date.now() - article.days_ago * 24 * 60 * 60 * 1000).toISOString();

    const { error: insertError } = await supabase.from("articles").upsert(
      {
        title: article.title,
        slug: article.slug,
        body: article.body,
        status: "published",
        author_id: authorId,
        category_id: categoryId,
        read_count: article.read_count,
        like_count: Math.floor(article.read_count * (0.03 + Math.random() * 0.05)),
        published_at: publishedAt,
        created_at: publishedAt,
        updated_at: publishedAt,
      },
      { onConflict: "slug" }
    );

    if (insertError) {
      console.error(`  Failed on "${article.title}":`, insertError.message);
      skipped++;
    } else {
      createdCount++;
    }
  }

  console.log(`\nDone. ${createdCount} articles created/updated, ${skipped} skipped.`);
}

main();
