/**
 * Simplified seed script: does NOT create any user accounts (avoiding the
 * Supabase Admin API entirely). Instead, it attaches the 60 generated
 * articles to writer account(s) you've already created normally through
 * /signup — round-robining across however many emails you list below.
 *
 * Usage:
 *   1. Sign up 1-3 writer accounts normally at /signup (pick "Writer").
 *   2. Edit the WRITER_EMAILS array below to match those real accounts.
 *   3. Run:  node scripts/seed-articles-simple.mjs
 */

import { createClient } from "@supabase/supabase-js";
import { readFileSync } from "fs";
import { fileURLToPath } from "url";
import { dirname, join } from "path";
import dotenv from "dotenv";

const __dirname = dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: join(__dirname, "..", ".env.local") });

// EDIT THIS: put the real email(s) of writer account(s) you signed up with.
const WRITER_EMAILS = ["you@example.com"];

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL;
const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
  console.error("\nMissing env vars — check .env.local has NEXT_PUBLIC_SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.\n");
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const seedData = JSON.parse(readFileSync(join(__dirname, "seed-data.json"), "utf-8"));

async function main() {
  const { data: writers, error: writerError } = await supabase
    .from("profiles")
    .select("id, email, name")
    .in("email", WRITER_EMAILS);

  if (writerError || !writers || writers.length === 0) {
    console.error(
      "\nCouldn't find any of these emails in the profiles table:\n  " +
        WRITER_EMAILS.join(", ") +
        "\n\nMake sure you've signed up with these exact emails first, and that they've " +
        "confirmed their account (check the profiles table in Supabase Table Editor to confirm).\n"
    );
    process.exit(1);
  }

  console.log(`Found ${writers.length} writer(s): ${writers.map((w) => w.name).join(", ")}\n`);

  const { data: categories, error: catError } = await supabase.from("categories").select("id, slug");
  if (catError || !categories || categories.length === 0) {
    console.error("\nCouldn't load categories — did you run 0001_init.sql?\n");
    process.exit(1);
  }
  const categoryIdBySlug = Object.fromEntries(categories.map((c) => [c.slug, c.id]));

  let createdCount = 0;
  let skipped = 0;

  for (let i = 0; i < seedData.articles.length; i++) {
    const article = seedData.articles[i];
    const author = writers[i % writers.length]; // round-robin across whatever writers you gave
    const categoryId = categoryIdBySlug[article.category_slug];

    if (!categoryId) {
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
        author_id: author.id,
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
