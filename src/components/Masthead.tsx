"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { motion } from "framer-motion";
import type { Profile } from "@/types/database";
import { AccountMenu } from "@/components/AccountMenu";
import { MobileMenu } from "@/components/MobileMenu";

const NAV_CATEGORIES = [
  { name: "Politics", slug: "politics" },
  { name: "Culture", slug: "culture" },
  { name: "Business", slug: "business" },
  { name: "Campus", slug: "campus" },
  { name: "Opinion", slug: "opinion" },
];

export function Masthead({ profile }: { profile: Profile | null }) {
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    function onScroll() {
      setScrolled(window.scrollY > 8);
    }
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const today = new Date().toLocaleDateString("en-US", {
    weekday: "long",
    month: "long",
    day: "numeric",
  });

  return (
    <header
      className={`sticky top-0 z-20 border-b transition-all duration-300 ${
        scrolled ? "glass-nav border-rule shadow-[0_4px_20px_rgba(20,23,28,0.06)]" : "border-transparent bg-paper"
      }`}
    >
      <div className="mono-label hidden justify-between border-b border-rule/60 px-6 py-2 sm:flex sm:px-10">
        <span>{today}</span>
        {profile?.role === "editor" && <span>Signed in as editor</span>}
        {profile?.role === "writer" && <span>Signed in as writer</span>}
      </div>
      <div className="flex items-center justify-between px-4 py-4 sm:px-10 sm:py-5">
        <Link href="/" className="group flex items-center font-display text-2xl font-bold tracking-tight sm:text-3xl">
          The{" "}
          <motion.span
            className="ml-1.5 text-signal"
            whileHover={{ rotate: [-2, 2, -2, 0] }}
            transition={{ duration: 0.4 }}
          >
            Gist
          </motion.span>
        </Link>

        <nav className="hidden gap-7 lg:flex">
          {NAV_CATEGORIES.map((c) => (
            <Link
              key={c.slug}
              href={`/category/${c.slug}`}
              className="relative text-sm font-medium text-ink-muted transition-colors hover:text-ink after:absolute after:-bottom-1 after:left-0 after:h-[1.5px] after:w-0 after:bg-signal after:transition-all after:duration-300 hover:after:w-full"
            >
              {c.name}
            </Link>
          ))}
          <Link
            href="/feedback"
            className="relative text-sm font-medium text-ink-muted transition-colors hover:text-ink after:absolute after:-bottom-1 after:left-0 after:h-[1.5px] after:w-0 after:bg-signal after:transition-all after:duration-300 hover:after:w-full"
          >
            Feedback
          </Link>
        </nav>

        <div className="hidden items-center gap-3 lg:flex">
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

          {/* One clear priority action per role, plus the account menu for everything else. */}
          {profile && (profile.role === "writer" || profile.role === "editor") && (
            <Link href={profile.role === "editor" ? "/admin/review" : "/writer/new"} className="btn-solid">
              {profile.role === "editor" ? "Review queue" : "✎ Write"}
            </Link>
          )}

          {profile && <AccountMenu profile={profile} />}
        </div>

        <MobileMenu profile={profile} />
      </div>
    </header>
  );
}
