"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

export function CommentForm({
  articleId,
  isSignedIn,
}: {
  articleId: string;
  isSignedIn: boolean;
}) {
  const [body, setBody] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();
  const supabase = createClient();

  if (!isSignedIn) {
    return (
      <div className="rounded border border-rule bg-surface p-5 text-sm text-ink-muted">
        <a href="/login" className="font-semibold text-ink underline decoration-signal">
          Log in
        </a>{" "}
        to join the discussion.
      </div>
    );
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!body.trim()) return;
    setSubmitting(true);
    setError(null);

    const {
      data: { user },
    } = await supabase.auth.getUser();

    const { error: insertError } = await supabase.from("comments").insert({
      article_id: articleId,
      author_id: user!.id,
      body: body.trim(),
    });

    setSubmitting(false);

    if (insertError) {
      setError("Couldn't post your comment. Try again.");
      return;
    }

    setBody("");
    router.refresh();
  }

  return (
    <form onSubmit={handleSubmit} className="mb-8">
      <textarea
        value={body}
        onChange={(e) => setBody(e.target.value)}
        placeholder="Add to the discussion..."
        rows={3}
        className="w-full rounded border border-rule bg-surface p-3.5 text-sm outline-none focus:border-ink"
      />
      {error && <p className="mt-2 text-sm text-danger">{error}</p>}
      <div className="mt-2 flex justify-end">
        <button type="submit" disabled={submitting} className="btn-solid disabled:opacity-50">
          {submitting ? "Posting…" : "Post comment"}
        </button>
      </div>
    </form>
  );
}
