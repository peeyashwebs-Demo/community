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

function SectionLabel({ children }: { children: React.ReactNode }) {
  return <p className="mono-label px-1 pb-2 pt-5 text-ink-muted/70">{children}</p>;
}

function Item({ href, children, onClick }: { href: string; children: React.ReactNode; onClick: () => void }) {
  return (
    <Link
      href={href}
      onClick={onClick}
      className="block rounded px-3 py-2.5 text-[15px] font-medium text-ink transition-colors hover:bg-paper"
    >
      {children}
    </Link>
  );
}

export function MobileMenu({ profile }: { profile: Profile | null }) {
  const [open, setOpen] = useState(false);
  const close = () => setOpen(false);

  return (
    <div className="lg:hidden">
      <button
        aria-label="Open menu"
        onClick={() => setOpen((v) => !v)}
        className="flex h-9 w-9 flex-col items-center justify-center gap-[5px]"
      >
        <motion.span animate={open ? { rotate: 45, y: 6 } : { rotate: 0, y: 0 }} className="block h-[2px] w-5 bg-ink" />
        <motion.span animate={open ? { opacity: 0 } : { opacity: 1 }} className="block h-[2px] w-5 bg-ink" />
        <motion.span animate={open ? { rotate: -45, y: -6 } : { rotate: 0, y: 0 }} className="block h-[2px] w-5 bg-ink" />
      </button>

      <AnimatePresence>
        {open && (
          <>
            {/* Backdrop */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={close}
              className="fixed inset-0 top-[65px] z-10 bg-ink/20 backdrop-blur-[2px]"
            />
            {/* Panel */}
            <motion.div
              initial={{ opacity: 0, y: -12 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -12 }}
              transition={{ duration: 0.2 }}
              className="fixed left-0 right-0 top-[65px] z-10 max-h-[calc(100vh-65px)] overflow-y-auto border-b border-rule bg-paper shadow-[0_16px_32px_rgba(20,23,28,0.12)]"
            >
              <div className="mx-auto max-w-md px-5 pb-8">
                {profile && (
                  <div className="flex items-center gap-3 border-b border-rule py-5">
                    <span className="flex h-10 w-10 items-center justify-center rounded-full bg-ink text-sm font-semibold text-paper">
                      {profile.name?.[0]?.toUpperCase() ?? "?"}
                    </span>
                    <div>
                      <p className="font-display text-base font-semibold">{profile.name}</p>
                      <p className="mono-label">{profile.role}</p>
                    </div>
                  </div>
                )}

                {profile && (profile.role === "writer" || profile.role === "editor") && (
                  <div className="border-b border-rule pb-3">
                    <SectionLabel>Writing</SectionLabel>
                    <Item href="/writer" onClick={close}>My stories</Item>
                    <Item href="/writer/new" onClick={close}>New draft</Item>
                  </div>
                )}

                {profile?.role === "editor" && (
                  <div className="border-b border-rule pb-3">
                    <SectionLabel>Editor tools</SectionLabel>
                    <Item href="/admin" onClick={close}>Dashboard</Item>
                    <Item href="/admin/review" onClick={close}>Review queue</Item>
                    <Item href="/admin/writers" onClick={close}>Writers</Item>
                    <Item href="/admin/comments" onClick={close}>Comments</Item>
                    <Item href="/admin/feedback" onClick={close}>Feedback inbox</Item>
                  </div>
                )}

                {profile?.role === "reader" && (
                  <div className="border-b border-rule pb-3">
                    <SectionLabel>Your account</SectionLabel>
                    <Item href="/me/likes" onClick={close}>Liked stories</Item>
                  </div>
                )}

                <div className="border-b border-rule pb-3">
                  <SectionLabel>Browse</SectionLabel>
                  <div className="grid grid-cols-2 gap-1">
                    {NAV_CATEGORIES.map((c) => (
                      <Item key={c.slug} href={`/category/${c.slug}`} onClick={close}>
                        {c.name}
                      </Item>
                    ))}
                  </div>
                  <Item href="/feedback" onClick={close}>Feedback</Item>
                </div>

                <div className="pt-5">
                  {!profile ? (
                    <div className="flex flex-col gap-2.5">
                      <Link href="/login" onClick={close} className="btn-ghost justify-center">
                        Log in
                      </Link>
                      <Link href="/signup" onClick={close} className="btn-solid justify-center">
                        Join The Gist
                      </Link>
                    </div>
                  ) : (
                    <SignOutButton className="btn-ghost w-full justify-center" />
                  )}
                </div>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </div>
  );
}
