# The Gist — Community News & Gist Platform

A working build of the platform described in the framework doc: writer drafts → editorial
review → published story → public reading and discussion. Built with Next.js (App Router),
Supabase (Postgres + Auth + Storage), Tailwind, Framer Motion, and Tiptap.

## What's implemented

- **Auth & roles** — Supabase Auth, 3 roles (`reader` / `writer` / `editor`). After signing in,
  you're routed straight to your workspace: writers → `/writer`, editors → `/admin`, readers →
  home. The masthead always shows a solid **"✎ Write"** button once you're signed in as a writer
  or editor.
- **Signup with role selection** — animated cards let someone apply as a **Reader** or
  **Writer** (both instant). **Editor** is shown but locked — invite-only, granted by an existing
  editor from `/admin/writers`, never self-service.
- **Immersive homepage** — animated gradient-mesh hero with live story/writer counts, a
  scroll-reactive glass masthead, hover-lift feed cards, and scroll-triggered reveal animations
  throughout.
- **Public side** — home feed, category pages, article reading view with a like button,
  comments (read-only when logged out).
- **Likes** — signed-in readers can "love" any published article, with a little pop animation.
  Atomic via a `toggle_like` RPC.
- **Feedback** — `/feedback`, open to anyone, with a star rating + message. Editors review
  submissions at `/admin/feedback`.
- **Writer workspace** (`/writer`) — dashboard, Tiptap editor with autosave, cover upload,
  submit-for-review, visible editor feedback on rejected pieces.
- **Admin** (`/admin`) — dashboard, review queue, writer management, comment moderation,
  feedback inbox.
- **Owner bootstrap** — visit `/claim-owner` once, signed in, to become the first editor. See
  below.
- **Mobile** — a real hamburger menu, and every admin/writer/review layout stacks cleanly on
  small screens.
- **Data model & state machine** — see `supabase/migrations/`. `draft → in_review →
  published/rejected`, with `request changes` sending a story back to `draft` with a note.
- **Seed content** — 60 published articles (10 per category) across 3 demo writer accounts, via
  `scripts/seed-articles.mjs`.

## Setup

1. **Create a Supabase project** at supabase.com.
2. **Run these migrations in order**, pasting each into the SQL editor and clicking Run:
   1. `0001_init.sql` — schema, state machine, RLS, storage bucket, categories
   2. `0002_security_hardening.sql` — Data API grants + blocks self-promotion to editor
   3. `0003_feedback.sql` — feedback table
   4. *(skip `0004_seed_articles.sql` — deprecated, see the note inside it)*
   5. `0005_owner_bootstrap.sql` — the one-time `claim_first_editor` RPC
   6. `0006_likes.sql` — likes table + `toggle_like` RPC
   7. `0007_fix_signup_role.sql` — **fixes the "signed up as writer, shows as reader" bug** — see below
3. **Copy your API keys**: Project Settings → API →
   - **Project URL**
   - **anon / public** key (sometimes labeled "publishable")
   - **service_role** key — only needed for the seed script below. Never put this one in a
     `NEXT_PUBLIC_` variable or any frontend code; it bypasses all security rules.
4. **Environment variables**: copy `.env.local.example` to `.env.local` and fill in all three:
   `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`.
5. **Install & run**:
   ```
   npm install
   npm run dev
   ```
6. **Seed 60 demo articles** (safe to re-run):
   ```
   npm run seed
   ```
7. **Become the editor** — see the next section.

## Becoming the editor (you, the owner)

1. Sign up through `/signup` — pick Reader or Writer, doesn't matter which.
2. While signed in, go to **`/claim-owner`** and click "Claim editor access."
3. This only works while there are zero editors anywhere in the project — true right after
   setup. Once it succeeds, you're redirected to `/admin`, and `/claim-owner` permanently
   refuses everyone from then on, including you again.
4. Any *further* editor promotions go through an existing editor visiting `/admin/writers`.
   There's intentionally no other way to grant editor access — that's what keeps it invite-only.

## Two bugs from the last round, fixed

**"Signed up as writer, but login still showed reader."** The old signup flow called
`signUp()`, then tried to set the new profile's role with a follow-up client-side update. If
your Supabase project requires email confirmation (the default), `signUp()` doesn't return an
active session — so that follow-up ran with no logged-in user, row-level security silently
blocked it, and the role stayed `reader`. `0007_fix_signup_role.sql` fixes this properly: the
requested role now travels inside the signup call's own metadata, and the database trigger that
creates the profile reads it directly at creation time — no session dependency, nothing for RLS
to block.

**Seed articles never showing up.** The old `0004_seed_articles.sql` inserted demo users
directly into Supabase's internal `auth.users` table via raw SQL — a known-fragile approach,
since that table's required columns differ across Supabase project versions and can fail
silently in the SQL editor. `scripts/seed-articles.mjs` replaces it with Supabase's official
Admin API (`supabase.auth.admin.createUser`), the supported way to create users
programmatically, which works the same regardless of project version.

## Seed accounts (after `npm run seed`)

| Email | Password |
|---|---|
| ada.chukwu@seed.thegist.demo | `SeedWriter!2026` |
| tari.amadi@seed.thegist.demo | `SeedWriter!2026` |
| chuka.eze@seed.thegist.demo | `SeedWriter!2026` |

For local/demo use — change or remove before treating this as a real production site.

## Deploying

Push to a GitHub repo and import into Vercel. In Vercel's project settings, add
`NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` (you don't need to add the
service_role key to Vercel — the seed script is meant to be run locally, once, against your
Supabase project directly, not as part of the deployed app).

## Verifying everything works end to end

1. `npm run seed` — confirm 60 articles show up on the homepage.
2. Sign up as a writer at `/signup` — confirm you land in `/writer` after logging in (not `/`).
3. Visit `/claim-owner`, claim editor access, confirm you land in `/admin`.
4. As the writer: `/writer/new` → write a story → submit for review.
5. As the editor: `/admin/review` → preview → Approve. Confirm the story is now public.
6. Log out, open an article, click the heart, confirm it prompts you to log in.
7. Log in as a reader, like the article and post a comment.
8. As the editor: `/admin/comments` → hide that comment, confirm it disappears publicly.

## Notes on what's stubbed vs. real

- Everything talks to real Supabase tables through the anon key + RLS — no mock data layer.
- Tag management (assigning tags to articles) has schema + RLS in place but no UI yet.
- The framework's stretch items (author profile pages, weekly digest, reading-progress
  indicator) aren't built yet.
