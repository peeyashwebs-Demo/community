"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { AnimatePresence, motion } from "framer-motion";
import type { Profile } from "@/types/database";
import { SignOutButton } from "@/components/SignOutButton";

export function AccountMenu({ profile }: { profile: Profile }) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function onClickOutside(e: MouseEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    }
    document.addEventListener("mousedown", onClickOutside);
    return () => document.removeEventListener("mousedown", onClickOutside);
  }, []);

  const initial = profile.name?.[0]?.toUpperCase() ?? "?";

  return (
    <div className="relative" ref={ref}>
      <button
        onClick={() => setOpen((v) => !v)}
        className="flex items-center gap-2 rounded-full border border-rule py-1 pl-1 pr-3 transition-colors hover:border-ink"
      >
        <span className="flex h-7 w-7 items-center justify-center rounded-full bg-ink text-xs font-semibold text-paper">
          {initial}
        </span>
        <span className="max-w-[100px] truncate text-sm font-medium">{profile.name}</span>
        <motion.svg
          animate={{ rotate: open ? 180 : 0 }}
          width="12"
          height="12"
          viewBox="0 0 24 24"
          fill="none"
        >
          <path d="M6 9l6 6 6-6" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
        </motion.svg>
      </button>

      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ opacity: 0, y: -8, scale: 0.97 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -8, scale: 0.97 }}
            transition={{ duration: 0.15 }}
            className="absolute right-0 top-full mt-2 w-64 overflow-hidden rounded border border-rule bg-surface shadow-[0_12px_32px_rgba(20,23,28,0.14)]"
          >
            <div className="border-b border-rule px-4 py-3">
              <p className="font-display text-sm font-semibold">{profile.name}</p>
              <p className="mono-label mt-0.5">{profile.role}</p>
            </div>

            {(profile.role === "writer" || profile.role === "editor") && (
              <div className="border-b border-rule py-2">
                <p className="mono-label px-4 pb-1.5 pt-1 text-ink-muted/70">Writing</p>
                <MenuLink href="/writer" onClick={() => setOpen(false)}>
                  My stories
                </MenuLink>
                <MenuLink href="/writer/new" onClick={() => setOpen(false)}>
                  New draft
                </MenuLink>
              </div>
            )}

            {profile.role === "editor" && (
              <div className="border-b border-rule py-2">
                <p className="mono-label px-4 pb-1.5 pt-1 text-ink-muted/70">Editor tools</p>
                <MenuLink href="/admin" onClick={() => setOpen(false)}>
                  Dashboard
                </MenuLink>
                <MenuLink href="/admin/review" onClick={() => setOpen(false)}>
                  Review queue
                </MenuLink>
                <MenuLink href="/admin/writers" onClick={() => setOpen(false)}>
                  Writers
                </MenuLink>
                <MenuLink href="/admin/comments" onClick={() => setOpen(false)}>
                  Comments
                </MenuLink>
                <MenuLink href="/admin/feedback" onClick={() => setOpen(false)}>
                  Feedback inbox
                </MenuLink>
              </div>
            )}

            {profile.role === "reader" && (
              <div className="border-b border-rule py-2">
                <p className="mono-label px-4 pb-1.5 pt-1 text-ink-muted/70">Your account</p>
                <MenuLink href="/me/likes" onClick={() => setOpen(false)}>
                  Liked stories
                </MenuLink>
              </div>
            )}

            <div className="p-3">
              <SignOutButton className="btn-ghost w-full" />
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

function MenuLink({
  href,
  children,
  onClick,
}: {
  href: string;
  children: React.ReactNode;
  onClick: () => void;
}) {
  return (
    <Link
      href={href}
      onClick={onClick}
      className="block px-4 py-2 text-[14px] font-medium text-ink transition-colors hover:bg-paper"
    >
      {children}
    </Link>
  );
}
