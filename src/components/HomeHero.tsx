"use client";

import Link from "next/link";
import { motion, useScroll, useTransform } from "framer-motion";
import { useRef } from "react";

// Lorem Picsum: a real-photography placeholder service built specifically for
// embedding in projects like this — deterministic per seed, no licensing
// friction, no API key. Paired with a brand-color duotone overlay below so it
// reads as an intentional, on-brand image rather than a random stock photo.
const HERO_IMAGE = "https://picsum.photos/seed/thegist-newsroom/1800/1100";

export function HomeHero({ storyCount, writerCount }: { storyCount: number; writerCount: number }) {
  const ref = useRef<HTMLElement>(null);
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start start", "end start"] });
  const imageY = useTransform(scrollYProgress, [0, 1], ["0%", "20%"]);
  const contentOpacity = useTransform(scrollYProgress, [0, 0.8], [1, 0]);

  return (
    <section ref={ref} className="relative h-[88vh] min-h-[560px] w-full overflow-hidden border-b border-rule">
      {/* Photo layer with slow Ken Burns zoom + scroll parallax */}
      <motion.div
        className="absolute inset-0"
        style={{ y: imageY }}
        initial={{ scale: 1.08 }}
        animate={{ scale: 1.18 }}
        transition={{ duration: 24, ease: "linear", repeat: Infinity, repeatType: "mirror" }}
      >
        <div
          className="h-full w-full bg-cover bg-center"
          style={{ backgroundImage: `url(${HERO_IMAGE})` }}
        />
      </motion.div>

      {/* Brand-color duotone treatment — ties any photo to the site's palette */}
      <div
        className="absolute inset-0"
        style={{
          background:
            "linear-gradient(180deg, rgba(20,23,28,0.55) 0%, rgba(20,23,28,0.72) 55%, rgba(20,23,28,0.92) 100%)",
        }}
      />
      <div
        className="absolute inset-0 mix-blend-color"
        style={{ backgroundColor: "#B23A2E" }}
      />
      <div className="absolute inset-0 bg-ink/25" />

      {/* Content */}
      <motion.div
        style={{ opacity: contentOpacity }}
        className="relative flex h-full flex-col items-center justify-center px-6 text-center"
      >
        <motion.p
          initial={{ opacity: 0, y: 8 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="mono-label mb-5 inline-block rounded-full border border-white/25 bg-white/10 px-4 py-1.5 text-white backdrop-blur-sm"
        >
          Draft → Review → Published
        </motion.p>

        <motion.h1
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.7, delay: 0.1 }}
          className="mb-5 max-w-4xl font-display text-[34px] font-semibold leading-[1.1] text-white sm:text-6xl md:text-7xl"
        >
          Where the community
          <br />
          writes the news.
        </motion.h1>

        <motion.p
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.7, delay: 0.2 }}
          className="mx-auto mb-9 max-w-xl font-body text-lg italic text-white/85"
        >
          Real writers, a real newsroom, and stories that pass through a real editor before they
          reach you.
        </motion.p>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.7, delay: 0.3 }}
          className="mb-10 flex flex-wrap items-center justify-center gap-3"
        >
          <a href="#feed" className="btn-solid px-6 py-3 text-[15px]">
            Start reading ↓
          </a>
          <Link
            href="/signup"
            className="inline-flex items-center justify-center rounded border border-white/40 bg-white/10 px-6 py-3 text-[15px] font-semibold text-white backdrop-blur-sm transition-all hover:-translate-y-[1px] hover:bg-white/20"
          >
            Write for The Gist
          </Link>
        </motion.div>

        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.5, duration: 0.7 }}
          className="mono-label flex flex-wrap items-center justify-center gap-6 text-white/80"
        >
          <span>
            <b className="font-semibold text-white">{storyCount}+</b> published stories
          </span>
          <span className="h-1 w-1 rounded-full bg-white/40" />
          <span>
            <b className="font-semibold text-white">{writerCount}</b> community writers
          </span>
        </motion.div>
      </motion.div>

      {/* Scroll cue */}
      <motion.div
        className="absolute bottom-7 left-1/2 -translate-x-1/2 text-white/70"
        animate={{ y: [0, 8, 0] }}
        transition={{ duration: 1.8, repeat: Infinity, ease: "easeInOut" }}
      >
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
          <path d="M12 5v14M5 12l7 7 7-7" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </motion.div>
    </section>
  );
}
