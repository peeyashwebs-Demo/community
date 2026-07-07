"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import type { Comment } from "@/types/database";

export function CommentModerationRow({ comment }: { comment: Comment }) {
  const [busy, setBusy] = useState(false);
  const router = useRouter();
  const supabase = createClient();

  async function setStatus(status: "visible" | "hidden" | "deleted") {
    setBusy(true);
    await supabase.from("comments").update({ status }).eq("id", comment.id);
    setBusy(false);
    router.refresh();
  }

  async function banAuthor() {
    setBusy(true);
    await supabase.from("profiles").update({ status: "suspended" }).eq("id", comment.author_id);
    setBusy(false);
    router.refresh();
  }

  return (
    <div className="border-b border-rule py-4">
      <div className="mono-label mb-2">
        {comment.author?.name ?? "Reader"} · {new Date(comment.created_at).toLocaleDateString()} ·{" "}
        {comment.status}
      </div>
      <p className="mb-3 text-[15px]">{comment.body}</p>
      <div className="flex flex-wrap gap-2">
        {comment.status !== "hidden" && (
          <button onClick={() => setStatus("hidden")} disabled={busy} className="btn-ghost">
            Hide
          </button>
        )}
        {comment.status === "hidden" && (
          <button onClick={() => setStatus("visible")} disabled={busy} className="btn-ghost">
            Restore
          </button>
        )}
        <button
          onClick={() => setStatus("deleted")}
          disabled={busy}
          className="rounded border border-danger/30 px-4 py-2.5 text-sm font-semibold text-danger hover:bg-danger/5"
        >
          Delete
        </button>
        <button onClick={banAuthor} disabled={busy} className="btn-ghost">
          Suspend author
        </button>
      </div>
    </div>
  );
}
