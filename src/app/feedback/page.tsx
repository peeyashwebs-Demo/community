"use client";

import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { createClient } from "@/lib/supabase/client";

export default function FeedbackPage() {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [message, setMessage] = useState("");
  const [rating, setRating] = useState(0);
  const [hoverRating, setHoverRating] = useState(0);
  const [submitting, setSubmitting] = useState(false);
  const [done, setDone] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const supabase = createClient();

  useEffect(() => {
    supabase.auth.getUser().then(async ({ data: { user } }) => {
      if (!user) return;
      const { data: profile } = await supabase.from("profiles").select("name, email").eq("id", user.id).single();
      if (profile) {
        setName(profile.name);
        setEmail(profile.email);
      }
    });
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);

    if (!name.trim() || !message.trim()) {
      setError("Tell us your name and a bit of feedback.");
      return;
    }

    setSubmitting(true);
    const {
      data: { user },
    } = await supabase.auth.getUser();

    const { error: insertError } = await supabase.from("feedback").insert({
      user_id: user?.id ?? null,
      name: name.trim(),
      email: email.trim() || null,
      message: message.trim(),
      rating: rating || null,
    });

    setSubmitting(false);

    if (insertError) {
      setError("Couldn't send that — try again in a moment.");
      return;
    }

    setDone(true);
  }

  return (
    <main className="mx-auto max-w-xl px-6 py-14 sm:py-16">
      <AnimatePresence mode="wait">
        {done ? (
          <motion.div
            key="done"
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            className="py-12 text-center"
          >
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ type: "spring", stiffness: 260, damping: 18 }}
              className="mx-auto mb-5 flex h-14 w-14 items-center justify-center rounded-full bg-verified/10"
            >
              <span className="text-2xl">✓</span>
            </motion.div>
            <h1 className="mb-2 font-display text-2xl font-semibold">Thank you</h1>
            <p className="font-body italic text-ink-muted">
              An editor will read this. If you left an email, we may follow up.
            </p>
          </motion.div>
        ) : (
          <motion.div key="form" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
            <p className="mono-label mb-2 text-signal">We're listening</p>
            <h1 className="mb-2 font-display text-3xl font-semibold sm:text-4xl">
              Tell us what's working
            </h1>
            <p className="mb-9 font-body italic text-ink-muted">
              Bug, idea, or just a thought about a story — it all goes straight to the editors.
            </p>

            <div className="mb-8 flex gap-2">
              {[1, 2, 3, 4, 5].map((n) => (
                <motion.button
                  key={n}
                  type="button"
                  whileHover={{ scale: 1.15 }}
                  whileTap={{ scale: 0.9 }}
                  onMouseEnter={() => setHoverRating(n)}
                  onMouseLeave={() => setHoverRating(0)}
                  onClick={() => setRating(n)}
                  className="text-3xl leading-none transition-colors"
                  aria-label={`Rate ${n} out of 5`}
                >
                  <span className={n <= (hoverRating || rating) ? "text-signal" : "text-rule"}>★</span>
                </motion.button>
              ))}
            </div>

            <AnimatePresence>
              {error && (
                <motion.div
                  initial={{ opacity: 0, height: 0 }}
                  animate={{ opacity: 1, height: "auto" }}
                  exit={{ opacity: 0, height: 0 }}
                  className="mb-5 overflow-hidden rounded border border-[#E2AFA6] bg-[#FBEAE7] px-3.5 py-2.5 text-sm text-[#8A2C21]"
                >
                  {error}
                </motion.div>
              )}
            </AnimatePresence>

            <form onSubmit={handleSubmit}>
              <div className="mb-5 grid gap-5 sm:grid-cols-2">
                <div>
                  <label className="mono-label mb-2 block">Name</label>
                  <input
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="Your name"
                    className="w-full rounded border border-rule bg-surface px-3.5 py-3 text-[15px] outline-none transition-all focus:border-ink focus:shadow-[0_0_0_3px_rgba(20,23,28,0.06)]"
                  />
                </div>
                <div>
                  <label className="mono-label mb-2 block">Email (optional)</label>
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="you@example.com"
                    className="w-full rounded border border-rule bg-surface px-3.5 py-3 text-[15px] outline-none transition-all focus:border-ink focus:shadow-[0_0_0_3px_rgba(20,23,28,0.06)]"
                  />
                </div>
              </div>

              <div className="mb-7">
                <label className="mono-label mb-2 block">Your feedback</label>
                <textarea
                  value={message}
                  onChange={(e) => setMessage(e.target.value)}
                  rows={5}
                  placeholder="What should we know?"
                  className="w-full rounded border border-rule bg-surface p-3.5 text-[15px] outline-none transition-all focus:border-ink focus:shadow-[0_0_0_3px_rgba(20,23,28,0.06)]"
                />
              </div>

              <motion.button
                type="submit"
                whileTap={{ scale: 0.98 }}
                disabled={submitting}
                className="btn-solid w-full disabled:opacity-60"
              >
                {submitting ? "Sending…" : "Send feedback"}
              </motion.button>
            </form>
          </motion.div>
        )}
      </AnimatePresence>
    </main>
  );
}
