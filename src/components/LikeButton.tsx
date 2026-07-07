"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { createClient } from "@/lib/supabase/client";

export function LikeButton({
  articleId,
  initialCount,
  initiallyLiked,
  isSignedIn,
}: {
  articleId: string;
  initialCount: number;
  initiallyLiked: boolean;
  isSignedIn: boolean;
}) {
  const [liked, setLiked] = useState(initiallyLiked);
  const [count, setCount] = useState(initialCount);
  const [busy, setBusy] = useState(false);
  const [burst, setBurst] = useState(false);
  const supabase = createClient();

  async function handleClick() {
    if (!isSignedIn) {
      window.location.href = "/login";
      return;
    }
    if (busy) return;

    setBusy(true);
    const nextLiked = !liked;
    // Optimistic update — the toggle_like RPC is the source of truth on refresh.
    setLiked(nextLiked);
    setCount((c) => c + (nextLiked ? 1 : -1));
    if (nextLiked) {
      setBurst(true);
      setTimeout(() => setBurst(false), 500);
    }

    const { error } = await supabase.rpc("toggle_like", { p_article_id: articleId });

    if (error) {
      // Revert on failure.
      setLiked(liked);
      setCount((c) => c + (nextLiked ? -1 : 1));
    }
    setBusy(false);
  }

  return (
    <button
      onClick={handleClick}
      disabled={busy}
      className="relative inline-flex items-center gap-2 rounded-full border border-rule px-4 py-2 transition-colors hover:border-ink disabled:opacity-70"
      aria-pressed={liked}
    >
      <span className="relative flex h-5 w-5 items-center justify-center">
        <motion.svg
          key={liked ? "liked" : "unliked"}
          width="20"
          height="20"
          viewBox="0 0 24 24"
          initial={{ scale: 0.7 }}
          animate={{ scale: 1 }}
          transition={{ type: "spring", stiffness: 400, damping: 15 }}
          fill={liked ? "#B23A2E" : "none"}
          stroke={liked ? "#B23A2E" : "#6B6860"}
          strokeWidth="2"
        >
          <path d="M12 21s-6.7-4.35-9.3-8.2C.8 9.9 1.5 6.3 4.4 4.9c2.2-1.05 4.6-.4 6.1 1.4l1.5 1.8 1.5-1.8c1.5-1.8 3.9-2.45 6.1-1.4 2.9 1.4 3.6 5 1.7 7.9C18.7 16.65 12 21 12 21z" />
        </motion.svg>

        <AnimatePresence>
          {burst && (
            <motion.span
              initial={{ scale: 0.4, opacity: 0.8 }}
              animate={{ scale: 2.2, opacity: 0 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.5 }}
              className="pointer-events-none absolute inset-0 rounded-full bg-signal/40"
            />
          )}
        </AnimatePresence>
      </span>
      <span className="mono-label">
        {count.toLocaleString()} {count === 1 ? "love" : "loves"}
      </span>
    </button>
  );
}
