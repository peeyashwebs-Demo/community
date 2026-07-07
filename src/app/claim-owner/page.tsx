"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { motion, AnimatePresence } from "framer-motion";
import { createClient } from "@/lib/supabase/client";

export default function ClaimOwnerPage() {
  const [status, setStatus] = useState<"idle" | "checking" | "success" | "taken" | "signed-out">(
    "idle"
  );
  const router = useRouter();
  const supabase = createClient();

  async function handleClaim() {
    setStatus("checking");

    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      setStatus("signed-out");
      return;
    }

    const { data, error } = await supabase.rpc("claim_first_editor");

    if (error) {
      setStatus("taken");
      return;
    }

    if (data === true) {
      setStatus("success");
      setTimeout(() => {
        router.push("/admin");
        router.refresh();
      }, 1400);
    } else {
      setStatus("taken");
    }
  }

  return (
    <main className="mx-auto flex min-h-[calc(100vh-73px)] max-w-md flex-col items-center justify-center px-6 text-center">
      <AnimatePresence mode="wait">
        {status === "success" ? (
          <motion.div key="success" initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }}>
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ type: "spring", stiffness: 260, damping: 18 }}
              className="mx-auto mb-5 flex h-14 w-14 items-center justify-center rounded-full bg-verified/10"
            >
              <span className="text-2xl">✓</span>
            </motion.div>
            <h1 className="mb-2 font-display text-2xl font-semibold">You're the editor now</h1>
            <p className="font-body italic text-ink-muted">Taking you to the admin dashboard…</p>
          </motion.div>
        ) : (
          <motion.div key="idle" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
            <p className="mono-label mb-2 text-signal">Owner setup</p>
            <h1 className="mb-3 font-display text-2xl font-semibold sm:text-3xl">
              Claim the first editor account
            </h1>
            <p className="mb-8 font-body italic text-ink-muted">
              This only works once — for whoever runs it before any editor exists. If you're
              reading this, that's probably you.
            </p>

            {status === "signed-out" && (
              <div className="mb-6 rounded border border-rule bg-surface p-4 text-sm text-ink-muted">
                You need to be signed in first.{" "}
                <Link href="/login?redirectTo=/claim-owner" className="font-semibold text-ink underline decoration-signal">
                  Log in
                </Link>{" "}
                or{" "}
                <Link href="/signup" className="font-semibold text-ink underline decoration-signal">
                  create an account
                </Link>
                , then come back to this page.
              </div>
            )}

            {status === "taken" && (
              <div className="mb-6 rounded border border-rule bg-surface p-4 text-sm text-ink-muted">
                An editor already exists on this project. Ask them to promote your account from{" "}
                <span className="font-mono text-xs">/admin/writers</span> instead.
              </div>
            )}

            <motion.button
              onClick={handleClaim}
              disabled={status === "checking"}
              whileTap={{ scale: 0.98 }}
              className="btn-solid w-full disabled:opacity-60"
            >
              {status === "checking" ? "Checking…" : "Claim editor access"}
            </motion.button>
          </motion.div>
        )}
      </AnimatePresence>
    </main>
  );
}
