"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { motion } from "framer-motion";
import { createClient } from "@/lib/supabase/client";

export default function ConfirmedPage() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const status = searchParams.get("status");
  const [role, setRole] = useState<string | null>(null);

  useEffect(() => {
    if (status !== "success") return;

    const supabase = createClient();
    supabase.auth.getUser().then(async ({ data: { user } }) => {
      if (!user) return;
      const { data: profile } = await supabase.from("profiles").select("role").eq("id", user.id).single();
      setRole(profile?.role ?? null);
    });
  }, [status]);

  function continueToApp() {
    if (role === "writer" || role === "editor") {
      router.push("/writer");
    } else {
      router.push("/");
    }
  }

  const isSuccess = status === "success";

  return (
    <main className="mx-auto flex min-h-[calc(100vh-73px)] max-w-md flex-col items-center justify-center px-6 text-center">
      <motion.div
        initial={{ scale: 0 }}
        animate={{ scale: 1 }}
        transition={{ type: "spring", stiffness: 260, damping: 18 }}
        className={`mb-6 flex h-16 w-16 items-center justify-center rounded-full ${
          isSuccess ? "bg-verified/10" : "bg-danger/10"
        }`}
      >
        {isSuccess ? (
          <svg width="30" height="30" viewBox="0 0 24 24" fill="none">
            <path d="M20 6L9 17l-5-5" stroke="#2F6F5E" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        ) : (
          <svg width="30" height="30" viewBox="0 0 24 24" fill="none">
            <path d="M18 6L6 18M6 6l12 12" stroke="#A32B2B" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        )}
      </motion.div>

      <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.15 }}>
        {isSuccess ? (
          <>
            <p className="mono-label mb-2 text-verified">You're in</p>
            <h1 className="mb-3 font-display text-2xl font-semibold sm:text-3xl">Welcome to The Gist</h1>
            <p className="mb-8 font-body italic text-ink-muted">
              You're signed in and ready to go.
            </p>
            <button onClick={continueToApp} className="btn-solid w-full">
              {role === "writer" || role === "editor" ? "Go to your workspace" : "Start reading"}
            </button>
          </>
        ) : (
          <>
            <p className="mono-label mb-2 text-danger">Link didn't work</p>
            <h1 className="mb-3 font-display text-2xl font-semibold sm:text-3xl">
              That confirmation link is invalid or expired
            </h1>
            <p className="mb-8 font-body italic text-ink-muted">
              Confirmation links only work once, and expire after a while. Try logging in — if your
              account still needs confirming, you can request a new link from there.
            </p>
            <Link href="/login" className="btn-solid w-full">
              Go to log in
            </Link>
          </>
        )}
      </motion.div>
    </main>
  );
}
