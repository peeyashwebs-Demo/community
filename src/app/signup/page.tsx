"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

export default function SignupPage() {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [done, setDone] = useState(false);
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  const supabase = createClient();

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);

    if (!name || !email || !password) {
      setError("Fill in your name, email, and a password.");
      return;
    }
    if (password.length < 8) {
      setError("Password needs to be at least 8 characters.");
      return;
    }

    setLoading(true);
    const { error: signUpError } = await supabase.auth.signUp({
      email,
      password,
      options: { data: { name } },
    });
    setLoading(false);

    if (signUpError) {
      setError(signUpError.message);
      return;
    }

    setDone(true);
  }

  if (done) {
    return (
      <main className="mx-auto max-w-md px-6 py-24 text-center">
        <p className="mono-label mb-3 text-verified">Check your inbox</p>
        <h1 className="mb-3 font-display text-2xl font-semibold">Confirm your email</h1>
        <p className="font-body text-ink-muted">
          We've sent a confirmation link to <strong>{email}</strong>. Once confirmed, you can log
          in and start commenting.
        </p>
        <Link href="/login" className="btn-ghost mt-8 inline-flex">
          Back to log in
        </Link>
      </main>
    );
  }

  return (
    <main className="mx-auto flex min-h-[calc(100vh-73px)] max-w-md items-center px-6 py-16">
      <div className="w-full">
        <h1 className="mb-1.5 font-display text-3xl font-semibold">Create a reader account</h1>
        <p className="mb-9 font-body italic text-ink-muted">
          Free, and only needed to comment on stories.
        </p>

        {error && (
          <div className="mb-5 rounded border border-[#E2AFA6] bg-[#FBEAE7] px-3.5 py-2.5 text-sm text-[#8A2C21]">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className="mb-5">
            <label className="mono-label mb-2 block">Name</label>
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Ada Chukwu"
              className="w-full rounded border border-rule bg-surface px-3.5 py-3 text-[15px] outline-none focus:border-ink"
            />
          </div>
          <div className="mb-5">
            <label className="mono-label mb-2 block">Email address</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="you@example.com"
              className="w-full rounded border border-rule bg-surface px-3.5 py-3 text-[15px] outline-none focus:border-ink"
            />
          </div>
          <div className="mb-7">
            <label className="mono-label mb-2 block">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="At least 8 characters"
              className="w-full rounded border border-rule bg-surface px-3.5 py-3 text-[15px] outline-none focus:border-ink"
            />
          </div>
          <button type="submit" disabled={loading} className="btn-solid w-full disabled:opacity-60">
            {loading ? "Creating account…" : "Create account"}
          </button>
        </form>

        <p className="mt-7 text-center text-[13.5px] text-ink-muted">
          Already have an account?{" "}
          <Link href="/login" className="font-semibold text-ink underline decoration-signal">
            Log in
          </Link>
        </p>
      </div>
    </main>
  );
}
