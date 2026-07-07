"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { motion, AnimatePresence } from "framer-motion";
import { createClient } from "@/lib/supabase/client";

type RoleChoice = "reader" | "writer" | "editor";

const ROLES: {
  id: RoleChoice;
  title: string;
  blurb: string;
  detail: string;
  locked?: boolean;
}[] = [
  {
    id: "reader",
    title: "Reader",
    blurb: "Read, comment, follow topics",
    detail: "Free. Instant access — comment on any story right away.",
  },
  {
    id: "writer",
    title: "Writer",
    blurb: "Draft and submit stories",
    detail: "Your drafts autosave. Submit for review whenever you're ready.",
  },
  {
    id: "editor",
    title: "Editor",
    blurb: "Review, publish, moderate",
    detail: "Invite-only — granted by an existing editor, not self-serve.",
    locked: true,
  },
];

export default function SignupPage() {
  const [selected, setSelected] = useState<RoleChoice | null>(null);
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
    const { data, error: signUpError } = await supabase.auth.signUp({
      email,
      password,
      options: { data: { name, requested_role: selected } },
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
      <main className="mx-auto flex min-h-[calc(100vh-73px)] max-w-md items-center justify-center px-6 text-center">
        <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
          <p className="mono-label mb-3 text-verified">Check your inbox</p>
          <h1 className="mb-3 font-display text-2xl font-semibold">Confirm your email</h1>
          <p className="font-body text-ink-muted">
            We've sent a confirmation link to <strong>{email}</strong>.
            {selected === "writer"
              ? " Once confirmed, log in and you'll land straight in your writer workspace."
              : " Once confirmed, you can log in and start commenting."}
          </p>
          <Link href="/login" className="btn-ghost mt-8 inline-flex">
            Back to log in
          </Link>
        </motion.div>
      </main>
    );
  }

  return (
    <main className="mx-auto max-w-3xl px-6 py-14 sm:py-16">
      <div className="mb-10 text-center">
        <p className="mono-label mb-2 text-signal">001 / Join The Gist</p>
        <h1 className="font-display text-3xl font-semibold sm:text-4xl">
          What brings you here?
        </h1>
      </div>

      <div className="mb-10 grid gap-4 sm:grid-cols-3">
        {ROLES.map((r) => (
          <motion.button
            key={r.id}
            type="button"
            disabled={r.locked}
            onClick={() => setSelected(r.id)}
            whileHover={r.locked ? {} : { y: -4 }}
            whileTap={r.locked ? {} : { scale: 0.98 }}
            className={`relative rounded border p-5 text-left transition-colors ${
              selected === r.id
                ? "border-ink bg-ink text-paper"
                : r.locked
                ? "cursor-not-allowed border-rule bg-surface/50 opacity-60"
                : "border-rule bg-surface hover:border-ink/40"
            }`}
          >
            {r.locked && (
              <span className="mono-label absolute right-4 top-5 text-ink-muted">🔒</span>
            )}
            <h3 className="mb-1.5 font-display text-lg font-semibold">{r.title}</h3>
            <p
              className={`mb-2 text-sm ${
                selected === r.id ? "text-paper/80" : "text-ink-muted"
              }`}
            >
              {r.blurb}
            </p>
            <p
              className={`text-xs leading-relaxed ${
                selected === r.id ? "text-paper/60" : "text-ink-muted/80"
              }`}
            >
              {r.detail}
            </p>
            {selected === r.id && (
              <motion.div
                layoutId="role-check"
                className="absolute -right-2 -top-2 flex h-6 w-6 items-center justify-center rounded-full bg-signal text-white"
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
              >
                ✓
              </motion.div>
            )}
          </motion.button>
        ))}
      </div>

      <AnimatePresence>
        {selected && selected !== "editor" && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: "auto" }}
            exit={{ opacity: 0, height: 0 }}
            className="mx-auto max-w-md overflow-hidden"
          >
            <div className="border-t border-rule pt-8">
              <h2 className="mb-1.5 font-display text-2xl font-semibold">
                Create your {selected} account
              </h2>
              <p className="mb-7 font-body italic text-ink-muted">
                {selected === "writer"
                  ? "You'll land in your workspace, ready to start a draft."
                  : "Free, and only needed to comment on stories."}
              </p>

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
                <div className="mb-5">
                  <label className="mono-label mb-2 block">Name</label>
                  <input
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="Ada Chukwu"
                    className="w-full rounded border border-rule bg-surface px-3.5 py-3 text-[15px] outline-none transition-all focus:border-ink focus:shadow-[0_0_0_3px_rgba(20,23,28,0.06)]"
                  />
                </div>
                <div className="mb-5">
                  <label className="mono-label mb-2 block">Email address</label>
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="you@example.com"
                    className="w-full rounded border border-rule bg-surface px-3.5 py-3 text-[15px] outline-none transition-all focus:border-ink focus:shadow-[0_0_0_3px_rgba(20,23,28,0.06)]"
                  />
                </div>
                <div className="mb-7">
                  <label className="mono-label mb-2 block">Password</label>
                  <input
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="At least 8 characters"
                    className="w-full rounded border border-rule bg-surface px-3.5 py-3 text-[15px] outline-none transition-all focus:border-ink focus:shadow-[0_0_0_3px_rgba(20,23,28,0.06)]"
                  />
                </div>
                <motion.button
                  type="submit"
                  whileTap={{ scale: 0.98 }}
                  disabled={loading}
                  className="btn-solid w-full disabled:opacity-60"
                >
                  {loading ? "Creating account…" : `Create ${selected} account`}
                </motion.button>
              </form>
            </div>
          </motion.div>
        )}

        {selected === "editor" && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: "auto" }}
            exit={{ opacity: 0, height: 0 }}
            className="mx-auto max-w-md overflow-hidden text-center"
          >
            <div className="rounded border border-rule bg-surface p-6">
              <p className="mb-2 font-display text-lg font-semibold">Editor access is invite-only</p>
              <p className="text-sm text-ink-muted">
                Sign up as a reader or writer first — an existing editor can promote your account
                from the admin dashboard whenever they're ready.
              </p>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      <p className="mt-10 text-center text-[13.5px] text-ink-muted">
        Already have an account?{" "}
        <Link href="/login" className="font-semibold text-ink underline decoration-signal">
          Log in
        </Link>
      </p>
    </main>
  );
}
