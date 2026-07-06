# The Gist — Community News & Gist Platform

A working build of the platform described in the framework doc: writer drafts → editorial
review → published story → public reading and discussion. Built with Next.js (App Router),
Supabase (Postgres + Auth + Storage), Tailwind, and Tiptap — matching `framework.md`.

## What's implemented

- **Auth & roles** — Supabase Auth, 3 roles (`reader` / `writer` / `editor`), enforced both in
  middleware (route redirects) and in Postgres row-level security (the real boundary).
- **Public side** — home feed (featured + latest + most-read), category pages, single-article
  reading view with the drop-cap typography treatment, comments (read-only when logged out).
- **Writer workspace** (`/writer`) — dashboard with status badges, a Tiptap editor with autosave
  (900ms debounce, visible "Saving…/Saved" indicator), cover image upload, submit-for-review,
  and visible editor feedback on rejected pieces.
- **Admin** (`/admin`) — dashboard (published this week, pending count, top stories), review
  queue (preview + Approve / Request changes / Reject, each logged to `review_logs`), writer
  management (invite/suspend), comment moderation (hide/delete/suspend author).
- **Data model & state machine** — see `supabase/migrations/0001_init.sql`. `draft → in_review →
  published/rejected`, with `request changes` sending a story back to `draft` with a note.

## Setup

1. **Create a Supabase project** at supabase.com.
2. **Run the migration**: open the SQL editor in your Supabase dashboard and paste the contents
   of `supabase/migrations/0001_init.sql`, then run it. This creates every table, the RLS
   policies, the `covers` storage bucket, and seeds the 6 categories.
3. **Copy your API keys**: Project Settings → API → copy the Project URL and `anon public` key.
4. **Environment variables**: copy `.env.local.example` to `.env.local` and fill in those two
   values.
5. **Install & run**:
   ```
   npm install
   npm run dev
   ```
6. **Create your first editor account**: sign up normally through `/signup` (this creates a
   `reader`), then in the Supabase Table Editor open `profiles` and change that row's `role` to
   `editor`. Every account after that can be promoted from `/admin/writers`.

## Deploying

Push this to a GitHub repo and import it into Vercel — add the same two environment variables
in Vercel's project settings. That gives you the "live deployment with a real domain" the brief
asks for.

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

- Everything above talks to real Supabase tables through the anon key + RLS — there's no mock
  data layer.
- Tag management (assigning tags to articles) has the schema and RLS in place
  (`article_tags`) but no UI yet — the framework's stretch items (author profile pages, weekly
  digest, reading-progress indicator) are also not built yet. Both are natural next additions
  once the core loop above is verified live.
