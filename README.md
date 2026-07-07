# The Gist — Community News & Gist Platform

A working build of the platform described in the framework doc: writer drafts → editorial
review → published story → public reading and discussion. Built with Next.js (App Router),
Supabase (Postgres + Auth + Storage), Tailwind, Framer Motion, and Tiptap.

## What's implemented

- **Auth & roles** — Supabase Auth, 3 roles (`reader` / `writer` / `editor`). After signing in,
  you're routed straight to your workspace: writers → `/writer`, editors → `/admin`, readers →
  home. The masthead always shows a solid **"✎ Write"** button once you're signed in as a writer
  or editor — no more hunting for where to write.
- **Signup with role selection** — animated cards let someone apply as a **Reader** or
  **Writer** (both instant). **Editor** is shown but locked — it's invite-only, granted by an
  existing editor from `/admin/writers`, never self-service. This is a deliberate security
  choice: letting anyone grant themselves publishing/moderation authority at signup would be a
  real hole, so editor promotion always goes through an existing editor's account.
- **Public side** — home feed, category pages, article reading view, comments (read-only when
  logged out).
- **Feedback** — `/feedback`, open to anyone (logged in or not), with a star rating + message.
  Editors review submissions at `/admin/feedback`.
- **Writer workspace** (`/writer`) — dashboard, Tiptap editor with autosave, cover upload,
  submit-for-review, visible editor feedback on rejected pieces.
- **Admin** (`/admin`) — dashboard, review queue, writer management, comment moderation,
  feedback inbox.
- **Mobile** — a proper hamburger menu on the masthead, and admin/writer/review layouts that
  stack cleanly on small screens instead of cramping.
- **Data model & state machine** — see `supabase/migrations/`. `draft → in_review →
  published/rejected`, with `request changes` sending a story back to `draft` with a note.
- **Likes** — signed-in readers can "love" any published article (heart button
  under the byline, with a little pop animation). Counts are atomic via a
  `toggle_like` RPC, so concurrent likes never race each other.
- **Owner bootstrap** — visit `/claim-owner` once, signed in, to become the very
  first editor — no manual database editing required. See "Becoming the editor"
  below.
- **Seed content** — 3 seed writer accounts and 60 published articles (10 per category) so the
  site never looks empty. See "Seed accounts" below.

## Becoming the editor (you, the owner)

1. Sign up normally through `/signup` — pick Reader or Writer, doesn't matter which.
2. While signed in, go to **`/claim-owner`** and click "Claim editor access."
3. This only works if there are zero editors anywhere in the project yet — which is true right
   after setup, before you've run this. Once it succeeds, you're redirected to `/admin`.
4. From then on, `/claim-owner` permanently refuses — including for you — since an editor now
   exists. Any *further* editor promotions go through an existing editor visiting
   `/admin/writers` and promoting someone from there. There's intentionally no way to add a
   second editor except through an existing one — that's the whole point of keeping editor
   access invite-only.

(The old approach — manually flipping `role` to `editor` in the Supabase Table Editor — still
works too, if you ever need it as a fallback.)

## Setup

1. **Create a Supabase project** at supabase.com.
2. **Run the migrations in order**, pasting each into the SQL editor and clicking Run:
   1. `supabase/migrations/0001_init.sql` — schema, state machine, RLS, storage bucket, categories
   2. `supabase/migrations/0002_security_hardening.sql` — Data API grants + blocks self-promotion to editor
   3. `supabase/migrations/0003_feedback.sql` — feedback table
   4. `supabase/migrations/0004_seed_articles.sql` — 3 demo writers + 60 published articles
   5. `supabase/migrations/0005_owner_bootstrap.sql` — the one-time `claim_first_editor` RPC
   6. `supabase/migrations/0006_likes.sql` — likes table + `toggle_like` RPC
3. **Copy your API keys**: Project Settings → API → copy the Project URL and the `anon`/`public`
   (also now called "publishable") key.
4. **Environment variables**: copy `.env.local.example` to `.env.local` and fill in those two
   values.
5. **Install & run**:
   ```
   npm install
   npm run dev
   ```
6. **Create your first editor account**: sign up normally through `/signup` (pick Reader or
   Writer — doesn't matter which), then in the Supabase Table Editor open `profiles` and change
   that row's `role` to `editor` directly. Every account after that can be promoted from
   `/admin/writers`.

## Seed accounts (after running 0004)

Three demo writer accounts exist with 20 published articles each, spread across all 6
categories. Their email/password (for testing the writer flow, or to promote one to editor via
the Supabase Table Editor):

| Email | Password |
|---|---|
| ada.chukwu@seed.thegist.demo | `SeedWriter!2026` |
| tari.amadi@seed.thegist.demo | `SeedWriter!2026` |
| chuka.eze@seed.thegist.demo | `SeedWriter!2026` |

These are for local/demo use — change or remove them before treating this as a real production
site with real users.

## Deploying

Push this to a GitHub repo and import it into Vercel — add the same two environment variables
in Vercel's project settings.

## Verifying the "Shipped when" checklist

1. Sign up a second account, promote it to `writer` from `/admin/writers` (using your editor
   account).
2. As the writer: `/writer/new` → write a story → submit for review.
3. As the editor: `/admin/review` → preview → Approve.
4. Log out, confirm the story is visible on `/` and at its `/article/[slug]` URL with no login.
5. Sign in as a reader, post a comment.
6. As the editor: `/admin/comments` → hide that comment, confirm it disappears from the public
   article page.

## Notes on what's stubbed vs. real

- Everything talks to real Supabase tables through the anon key + RLS — no mock data layer.
- Tag management (assigning tags to articles) has the schema and RLS in place
  (`article_tags`) but no UI yet.
- The framework's stretch items (author profile pages, weekly digest, reading-progress
  indicator) aren't built yet.

