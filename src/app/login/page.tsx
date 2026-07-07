"use client";

import { useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import Link from "next/link";
import { motion, AnimatePresence } from "framer-motion";
import { createClient } from "@/lib/supabase/client";
import { GoogleSignInButton } from "@/components/GoogleSignInButton";

const ROLE_INFO = {
  reader: { label: "Reader", blurb: "Read stories, comment, follow topics." },
  writer: { label: "Writer", blurb: "Draft, submit, and track your stories." },
  editor: { label: "Editor", blurb: "Review queue, moderation, dashboard." },
};

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [detectedRole, setDetectedRole] = useState<keyof typeof ROLE_INFO | null>(null);
  const router = useRouter();
  const searchParams = useSearchParams();
  const supabase = createClient();

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);

    if (!email || !password) {
      setError("Enter both your email and password to continue.");
      return;
    }

    setLoading(true);
    const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (signInError || !signInData.user) {
      setLoading(false);
      setError("That email and password don't match. Try again, or reset your password.");
      return;
    }

    const { data: profile } = await supabase
      .from("profiles")
      .select("role, status")
      .eq("id", signInData.user.id)
      .single();

    if (profile?.status === "suspended") {
      await supabase.auth.signOut();
      setLoading(false);
      setError("This account has been suspended. Contact an editor if you think that's wrong.");
      return;
    }

    const role = (profile?.role ?? "reader") as keyof typeof ROLE_INFO;
    setDetectedRole(role);

    // Brief pause so the "signed in as ___" animation is actually seen.
    await new Promise((r) => setTimeout(r, 650));

    const redirectTo =
      searchParams.get("redirectTo") || (role === "editor" ? "/admin" : role === "writer" ? "/writer" : "/");
    router.push(redirectTo);
    router.refresh();
  }

  return (
    <div className="grid min-h-[calc(100vh-73px)] lg:grid-cols-[1.1fr_1fr]">
      {/* Editorial side panel */}
      <aside className="relative hidden flex-col justify-between overflow-hidden bg-ink p-16 text-paper lg:flex">
        <motion.div
          className="pointer-events-none absolute -left-32 -top-32 h-96 w-96 rounded-full bg-signal/20 blur-3xl"
          animate={{ x: [0, 40, 0], y: [0, 30, 0] }}
          transition={{ duration: 10, repeat: Infinity, ease: "easeInOut" }}
        />
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
        >
          <p className="mono-label text-[#B8A98F]">002 / Sign in</p>
          <h1 className="mt-4 max-w-[9.5ch] font-display text-4xl font-medium leading-tight">
            Where the community writes the news.
          </h1>
          <p className="mt-5 max-w-[38ch] font-body text-[17px] italic leading-relaxed text-[#D9D3C4]">
            "Every story on this page passed through a real editor before it reached you — that's
            the whole point."
          </p>
        </motion.div>
        <motion.div
          className="mono-label flex flex-wrap gap-6 text-[#9A9184]"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.3, duration: 0.6 }}
        >
          <span>
            <b className="font-medium text-paper">128</b> writers
          </span>
          <span>
            <b className="font-medium text-paper">1,940</b> published stories
          </span>
        </motion.div>
      </aside>

      {/* Form side */}
      <div className="flex items-center justify-center p-6 py-12 sm:py-16">
        <motion.div
          className="w-full max-w-[400px]"
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.45 }}
        >
          <AnimatePresence mode="wait">
            {detectedRole ? (
              <motion.div
                key="detected"
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                className="flex flex-col items-center py-10 text-center"
              >
                <motion.div
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  transition={{ type: "spring", stiffness: 260, damping: 18 }}
                  className="mb-5 flex h-14 w-14 items-center justify-center rounded-full bg-verified/10"
                >
                  <svg width="26" height="26" viewBox="0 0 24 24" fill="none">
                    <path
                      d="M20 6L9 17l-5-5"
                      stroke="#2F6F5E"
                      strokeWidth="2.5"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    />
                  </svg>
                </motion.div>
                <p className="mono-label mb-2">Signed in as</p>
                <h2 className="font-display text-2xl font-semibold">{ROLE_INFO[detectedRole].label}</h2>
                <p className="mt-2 text-sm text-ink-muted">Taking you to your workspace…</p>
              </motion.div>
            ) : (
              <motion.div key="form" initial={{ opacity: 1 }} exit={{ opacity: 0 }}>
                <h2 className="mb-1.5 font-display text-3xl font-semibold">Welcome back</h2>
                <p className="mb-9 font-body text-base italic text-ink-muted">
                  Sign in to comment, publish, or moderate.
                </p>

                <AnimatePresence>
                  {error && (
                    <motion.div
                      initial={{ opacity: 0, height: 0 }}
                      animate={{ opacity: 1, height: "auto" }}
                      exit={{ opacity: 0, height: 0 }}
                      className="mb-5 flex items-center gap-2 overflow-hidden rounded border border-[#E2AFA6] bg-[#FBEAE7] px-3.5 py-2.5 text-sm text-[#8A2C21]"
                    >
                      <span>⚠</span>
                      <span>{error}</span>
                    </motion.div>
                  )}
                </AnimatePresence>

                <form onSubmit={handleSubmit}>
                  <div className="mb-5">
                    <label htmlFor="email" className="mono-label mb-2 block">
                      Email address
                    </label>
                    <input
                      id="email"
                      type="email"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      placeholder="you@example.com"
                      className="w-full rounded border border-rule bg-surface px-3.5 py-3 text-[15px] outline-none transition-all focus:border-ink focus:shadow-[0_0_0_3px_rgba(20,23,28,0.06)]"
                    />
                  </div>

                  <div className="mb-5">
                    <label htmlFor="password" className="mono-label mb-2 block">
                      Password
                    </label>
                    <input
                      id="password"
                      type="password"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      placeholder="••••••••"
                      className="w-full rounded border border-rule bg-surface px-3.5 py-3 text-[15px] outline-none transition-all focus:border-ink focus:shadow-[0_0_0_3px_rgba(20,23,28,0.06)]"
                    />
                  </div>

                  <motion.button
                    type="submit"
                    disabled={loading}
                    whileTap={{ scale: 0.98 }}
                    className="btn-solid w-full disabled:opacity-60"
                  >
                    {loading ? "Signing in…" : "Sign in"}
                  </motion.button>
                </form>

                <div className="my-6 flex items-center gap-3">
                  <div className="h-px flex-1 bg-rule" />
                  <span className="mono-label">or</span>
                  <div className="h-px flex-1 bg-rule" />
                </div>

                <GoogleSignInButton />

                <div className="mb-7 mt-7 flex gap-2.5 rounded border border-rule bg-surface p-3.5">
                  <span className="mt-1.5 h-1.5 w-1.5 flex-shrink-0 rounded-full bg-verified" />
                  <p className="text-[13px] leading-relaxed text-ink-muted">
                    Writers and editors use the same login — your workspace appears automatically
                    based on your role once you're in.
                  </p>
                </div>

                <p className="text-center text-[13.5px] text-ink-muted">
                  New here?{" "}
                  <Link href="/signup" className="font-semibold text-ink underline decoration-signal">
                    Create an account
                  </Link>{" "}
                  as a reader or writer.
                </p>
              </motion.div>
            )}
          </AnimatePresence>
        </motion.div>
      </div>
    </div>
  );
}
