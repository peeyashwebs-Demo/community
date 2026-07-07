import Link from "next/link";
import type { Profile } from "@/types/database";
import { SignOutButton } from "@/components/SignOutButton";
import { MobileMenu } from "@/components/MobileMenu";

const NAV_CATEGORIES = [
  { name: "Politics", slug: "politics" },
  { name: "Culture", slug: "culture" },
  { name: "Business", slug: "business" },
  { name: "Campus", slug: "campus" },
  { name: "Opinion", slug: "opinion" },
];

export function Masthead({ profile }: { profile: Profile | null }) {
  const today = new Date().toLocaleDateString("en-US", {
    weekday: "long",
    month: "long",
    day: "numeric",
  });

  return (
    <header className="sticky top-0 z-20 border-b border-rule bg-paper">
      <div className="mono-label hidden justify-between border-b border-rule px-6 py-2 sm:flex sm:px-10">
        <span>{today}</span>
        {profile?.role === "editor" && <span>Signed in as editor</span>}
        {profile?.role === "writer" && <span>Signed in as writer</span>}
      </div>
      <div className="flex items-center justify-between px-6 py-4 sm:py-5 sm:px-10">
        <Link href="/" className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
          The <span className="text-signal">Gist</span>
        </Link>

        <nav className="hidden gap-7 md:flex">
          {NAV_CATEGORIES.map((c) => (
            <Link
              key={c.slug}
              href={`/category/${c.slug}`}
              className="text-sm font-medium text-ink-muted transition-colors hover:text-ink"
            >
              {c.name}
            </Link>
          ))}
          <Link
            href="/feedback"
            className="text-sm font-medium text-ink-muted transition-colors hover:text-ink"
          >
            Feedback
          </Link>
        </nav>

        <div className="hidden items-center gap-3 md:flex">
          {!profile && (
            <>
              <Link href="/login" className="btn-ghost">
                Log in
              </Link>
              <Link href="/signup" className="btn-solid">
                Join The Gist
              </Link>
            </>
          )}

          {/* Writers AND editors both get the same prominent "write" CTA —
              this is the fix for "nowhere to write": it's a solid button,
              not a quiet link, and it's always visible once you're signed in
              as either role. */}
          {profile && (profile.role === "writer" || profile.role === "editor") && (
            <Link href="/writer" className="btn-solid">
              ✎ Write
            </Link>
          )}

          {profile?.role === "editor" && (
            <Link href="/admin" className="btn-ghost">
              Admin
            </Link>
          )}

          {profile && <SignOutButton />}
        </div>

        <MobileMenu profile={profile} />
      </div>
    </header>
  );
}
