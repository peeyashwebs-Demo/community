"use client";

import { useState } from "react";
import Link from "next/link";
import { AnimatePresence, motion } from "framer-motion";
import type { Profile } from "@/types/database";
import { SignOutButton } from "@/components/SignOutButton";

const NAV_CATEGORIES = [
  { name: "Politics", slug: "politics" },
  { name: "Culture", slug: "culture" },
  { name: "Business", slug: "business" },
  { name: "Campus", slug: "campus" },
  { name: "Opinion", slug: "opinion" },
  { name: "Sports", slug: "sports" },
];

export function MobileMenu({ profile }: { profile: Profile | null }) {
  const [open, setOpen] = useState(false);

  return (
    <div className="md:hidden">
      <button
        aria-label="Open menu"
        onClick={() => setOpen((v) => !v)}
        className="flex h-9 w-9 flex-col items-center justify-center gap-[5px]"
      >
        <motion.span
          animate={open ? { rotate: 45, y: 6 } : { rotate: 0, y: 0 }}
          className="block h-[2px] w-5 bg-ink"
        />
        <motion.span
          animate={open ? { opacity: 0 } : { opacity: 1 }}
          className="block h-[2px] w-5 bg-ink"
        />
        <motion.span
          animate={open ? { rotate: -45, y: -6 } : { rotate: 0, y: 0 }}
          className="block h-[2px] w-5 bg-ink"
        />
      </button>

      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: "auto" }}
            exit={{ opacity: 0, height: 0 }}
            className="overflow-hidden border-b border-rule bg-paper"
          >
            <div className="flex flex-col gap-1 px-6 pb-6 pt-2">
              {NAV_CATEGORIES.map((c) => (
                <Link
                  key={c.slug}
                  href={`/category/${c.slug}`}
                  onClick={() => setOpen(false)}
                  className="border-b border-rule py-3 text-[15px] font-medium text-ink"
                >
                  {c.name}
                </Link>
              ))}
              <Link
                href="/feedback"
                onClick={() => setOpen(false)}
                className="border-b border-rule py-3 text-[15px] font-medium text-ink"
              >
                Feedback
              </Link>

              <div className="mt-4 flex flex-col gap-2.5">
                {!profile && (
                  <>
                    <Link href="/login" onClick={() => setOpen(false)} className="btn-ghost justify-center">
                      Log in
                    </Link>
                    <Link href="/signup" onClick={() => setOpen(false)} className="btn-solid justify-center">
                      Join The Gist
                    </Link>
                  </>
                )}

                {profile && (profile.role === "writer" || profile.role === "editor") && (
                  <Link
                    href="/writer"
                    onClick={() => setOpen(false)}
                    className="btn-solid justify-center"
                  >
                    ✎ Writer workspace
                  </Link>
                )}

                {profile?.role === "editor" && (
                  <Link href="/admin" onClick={() => setOpen(false)} className="btn-ghost justify-center">
                    Admin
                  </Link>
                )}

                {profile && <SignOutButton />}
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
