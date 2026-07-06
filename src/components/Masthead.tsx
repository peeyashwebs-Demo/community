import Link from "next/link";
import type { Profile } from "@/types/database";
import { SignOutButton } from "@/components/SignOutButton";

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
    <header className="sticky top-0 z-10 border-b border-rule bg-paper">
      <div className="mono-label flex justify-between border-b border-rule px-6 py-2 sm:px-10">
        <span>{today}</span>
        {profile?.role === "editor" && <span>Signed in as editor</span>}
      </div>
      <div className="flex items-center justify-between px-6 py-5 sm:px-10">
        <Link href="/" className="font-display text-3xl font-bold tracking-tight">
          The <span className="text-signal">Gist</span>
        </Link>

        <nav className="hidden gap-7 md:flex">
          {NAV_CATEGORIES.map((c) => (
            <Link
              key={c.slug}
              href={`/category/${c.slug}`}
              className="text-sm font-medium text-ink-muted hover:text-ink"
            >
              {c.name}
            </Link>
          ))}
        </nav>

        <div className="flex items-center gap-3">
          {!profile && (
            <>
              <Link href="/login" className="btn-ghost">
                Log in
              </Link>
              <Link href="/writer" className="btn-solid">
                Start writing
              </Link>
            </>
          )}

          {profile && (profile.role === "writer" || profile.role === "editor") && (
            <Link href="/writer" className="btn-ghost">
              Writer workspace
            </Link>
          )}

          {profile?.role === "editor" && (
            <Link href="/admin" className="btn-ghost">
              Admin
            </Link>
          )}

          {profile && <SignOutButton />}
        </div>
      </div>
    </header>
  );
}
