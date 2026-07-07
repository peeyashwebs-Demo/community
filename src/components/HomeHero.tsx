"use client";

import Link from "next/link";
import { motion } from "framer-motion";

export function HomeHero({ storyCount, writerCount }: { storyCount: number; writerCount: number }) {
  return (
    <section className="hero-mesh relative overflow-hidden border-b border-rule px-6 py-16 sm:px-10 sm:py-24">
      <motion.div
        className="pointer-events-none absolute -right-24 -top-24 h-72 w-72 rounded-full bg-signal/10 blur-3xl"
        animate={{ scale: [1, 1.15, 1], opacity: [0.6, 0.9, 0.6] }}
        transition={{ duration: 8, repeat: Infinity, ease: "easeInOut" }}
      />
      <motion.div
        className="pointer-events-none absolute -bottom-32 -left-16 h-80 w-80 rounded-full bg-verified/10 blur-3xl"
        animate={{ scale: [1, 1.1, 1] }}
        transition={{ duration: 10, repeat: Infinity, ease: "easeInOut", delay: 1 }}
      />

      <div className="relative mx-auto max-w-3xl text-center">
        <motion.p
          initial={{ opacity: 0, y: 8 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="mono-label mb-5 inline-block rounded-full border border-rule bg-surface/70 px-4 py-1.5 text-signal"
        >
          Draft → Review → Published
        </motion.p>

        <motion.h1
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.1 }}
          className="mb-5 font-display text-4xl font-semibold leading-[1.1] sm:text-6xl"
        >
          Where the community
          <br />
          writes the news.
        </motion.h1>

        <motion.p
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.2 }}
          className="mx-auto mb-9 max-w-xl font-body text-lg italic text-ink-muted"
        >
          Real writers, a real newsroom, and stories that pass through a real editor before they
          reach you.
        </motion.p>

        <motion.div
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.3 }}
          className="mb-10 flex flex-wrap items-center justify-center gap-3"
        >
          <a href="#feed" className="btn-solid px-6 py-3 text-[15px]">
            Start reading ↓
          </a>
          <Link href="/signup" className="btn-ghost bg-surface/70 px-6 py-3 text-[15px]">
            Write for The Gist
          </Link>
        </motion.div>

        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.5, duration: 0.6 }}
          className="mono-label flex flex-wrap items-center justify-center gap-6 text-ink-muted"
        >
          <span>
            <b className="font-semibold text-ink">{storyCount}+</b> published stories
          </span>
          <span className="h-1 w-1 rounded-full bg-rule" />
          <span>
            <b className="font-semibold text-ink">{writerCount}</b> community writers
          </span>
        </motion.div>
      </div>
    </section>
  );
}
