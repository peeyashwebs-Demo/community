"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import type { Article } from "@/types/database";

export function ReviewQueueItem({ article }: { article: Article }) {
  const [expanded, setExpanded] = useState(false);
  const [note, setNote] = useState("");
  const [pendingAction, setPendingAction] = useState<"reject" | "request_changes" | null>(null);
  const [busy, setBusy] = useState(false);
  const router = useRouter();
  const supabase = createClient();

  async function logAndUpdate(
    action: "approve" | "reject" | "request_changes",
    updates: Record<string, unknown>
  ) {
    setBusy(true);
    const {
      data: { user },
    } = await supabase.auth.getUser();

    await supabase.from("articles").update(updates).eq("id", article.id);
    await supabase.from("review_logs").insert({
      article_id: article.id,
      editor_id: user!.id,
      action,
      note: (updates.review_note as string) ?? null,
    });
    setBusy(false);
    router.refresh();
  }

  function approve() {
    logAndUpdate("approve", { status: "published", review_note: null });
  }

  function confirmNoted(action: "reject" | "request_changes") {
    if (!note.trim()) return;
    logAndUpdate(action, {
      status: action === "reject" ? "rejected" : "draft",
      review_note: note.trim(),
    });
    setPendingAction(null);
    setNote("");
  }

  return (
    <div className="border-b border-rule py-6">
      <div className="flex items-start justify-between gap-6">
        <div className="min-w-0 flex-1">
          <p className="mono-label mb-1.5">By {article.author?.name ?? "Unknown"}</p>
          <h3 className="mb-2 font-display text-xl font-semibold">
            {article.title || "Untitled draft"}
          </h3>
          <button
            onClick={() => setExpanded((v) => !v)}
            className="text-sm font-medium text-ink underline decoration-rule"
          >
            {expanded ? "Hide preview" : "Preview story"}
          </button>
          {expanded && (
            <div
              className="prose-article mt-4 max-h-96 overflow-y-auto rounded border border-rule bg-paper p-5 text-base"
              dangerouslySetInnerHTML={{ __html: article.body }}
            />
          )}
        </div>

        <div className="flex flex-shrink-0 flex-col gap-2">
          <button onClick={approve} disabled={busy} className="btn-solid whitespace-nowrap">
            Approve
          </button>
          <button
            onClick={() => setPendingAction("request_changes")}
            disabled={busy}
            className="btn-ghost whitespace-nowrap"
          >
            Request changes
          </button>
          <button
            onClick={() => setPendingAction("reject")}
            disabled={busy}
            className="whitespace-nowrap rounded border border-danger/30 px-4 py-2.5 text-sm font-semibold text-danger hover:bg-danger/5"
          >
            Reject
          </button>
        </div>
      </div>

      {pendingAction && (
        <div className="mt-4 rounded border border-rule bg-paper p-4">
          <label className="mono-label mb-2 block">
            {pendingAction === "reject" ? "Reason for rejecting" : "What needs to change"}
          </label>
          <textarea
            value={note}
            onChange={(e) => setNote(e.target.value)}
            rows={2}
            placeholder="Give the writer something specific to act on…"
            className="mb-3 w-full rounded border border-rule bg-surface p-3 text-sm outline-none focus:border-ink"
          />
          <div className="flex gap-2">
            <button
              onClick={() => confirmNoted(pendingAction)}
              disabled={!note.trim() || busy}
              className="btn-solid disabled:opacity-50"
            >
              Confirm
            </button>
            <button onClick={() => setPendingAction(null)} className="btn-ghost">
              Cancel
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
