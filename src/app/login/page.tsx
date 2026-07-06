"use client";

import { useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/client";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
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
    const { error: signInError } = await supabase.auth.signInWithPassword({ email, password });
    setLoading(false);

    if (signInError) {
      setError("That email and password don't match. Try again, or reset your password.");
      return;
    }

    const redirectTo = searchParams.get("redirectTo") || "/";
    router.push(redirectTo);
    router.refresh();
  }

  return (
    <div className="grid min-h-[calc(100vh-73px)] lg:grid-cols-[1.1fr_1fr]">
      {/* Editorial side panel */}
      <aside className="hidden flex-col justify-between overflow-hidden bg-ink p-16 text-paper lg:flex">
        <div>
          <p className="mono-label text-[#B8A98F]">002 / Sign in</p>
          <h1 className="mt-4 max-w-[9.5ch] font-display text-4xl font-medium leading-tight">
            Where the community writes the news.
          </h1>
          <p className="mt-5 max-w-[38ch] font-body text-[17px] italic leading-relaxed text-[#D9D3C4]">
            "Every story on this page passed through a real editor before it reached you — that's
            the whole point."
          </p>
        </div>
        <div className="mono-label flex flex-wrap gap-6 text-[#9A9184]">
          <span>
            <b className="font-medium text-paper">128</b> writers
          </span>
          <span>
            <b className="font-medium text-paper">1,940</b> published stories
          </span>
        </div>
      </aside>

      {/* Form side */}
      <div className="flex items-center justify-center p-6 py-16">
        <div className="w-full max-w-[400px]">
          <h2 className="mb-1.5 font-display text-3xl font-semibold">Welcome back</h2>
          <p className="mb-9 font-body text-base italic text-ink-muted">
            Sign in to comment, publish, or moderate.
          </p>

          {error && (
            <div className="mb-5 flex items-center gap-2 rounded border border-[#E2AFA6] bg-[#FBEAE7] px-3.5 py-2.5 text-sm text-[#8A2C21]">
              <span>⚠</span>
              <span>{error}</span>
            </div>
          )}

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
                className="w-full rounded border border-rule bg-surface px-3.5 py-3 text-[15px] outline-none focus:border-ink"
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
                className="w-full rounded border border-rule bg-surface px-3.5 py-3 text-[15px] outline-none focus:border-ink"
              />
            </div>

            <button type="submit" disabled={loading} className="btn-solid w-full disabled:opacity-60">
              {loading ? "Signing in…" : "Sign in"}
            </button>
          </form>

          <div className="my-7 flex items-center gap-3.5">
            <div className="mono-label" />
          </div>

          <div className="mb-7 flex gap-2.5 rounded border border-rule bg-surface p-3.5">
            <span className="mt-1.5 h-1.5 w-1.5 flex-shrink-0 rounded-full bg-verified" />
            <p className="text-[13px] leading-relaxed text-ink-muted">
              Writers and editors use the same login — your workspace or review queue appears
              automatically based on your role once you're in.
            </p>
          </div>

          <p className="text-center text-[13.5px] text-ink-muted">
            New here?{" "}
            <Link href="/signup" className="font-semibold text-ink underline decoration-signal">
              Create a reader account
            </Link>{" "}
            — it's free, and only needed to comment.
          </p>
        </div>
      </div>
    </div>
  );
}
