"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import type { Profile } from "@/types/database";

export function WriterRow({ profile }: { profile: Profile }) {
  const [busy, setBusy] = useState(false);
  const router = useRouter();
  const supabase = createClient();

  async function toggleStatus() {
    setBusy(true);
    const newStatus = profile.status === "active" ? "suspended" : "active";
    await supabase.from("profiles").update({ status: newStatus }).eq("id", profile.id);
    setBusy(false);
    router.refresh();
  }

  async function promoteToWriter() {
    setBusy(true);
    await supabase.from("profiles").update({ role: "writer" }).eq("id", profile.id);
    setBusy(false);
    router.refresh();
  }

  async function promoteToEditor() {
    if (
      !window.confirm(
        `Make ${profile.name} an editor? They'll be able to publish, reject, and moderate any story or comment on the site.`
      )
    ) {
      return;
    }
    setBusy(true);
    await supabase.from("profiles").update({ role: "editor" }).eq("id", profile.id);
    setBusy(false);
    router.refresh();
  }

  return (
    <div className="flex flex-col gap-3 border-b border-rule py-4 sm:flex-row sm:items-center sm:justify-between">
      <div className="min-w-0">
        <p className="truncate font-display font-medium">{profile.name}</p>
        <p className="mono-label truncate">
          {profile.email} · {profile.role}
          {profile.status === "suspended" && <span className="text-danger"> · suspended</span>}
        </p>
      </div>
      <div className="flex flex-wrap gap-2">
        {profile.role === "reader" && (
          <button onClick={promoteToWriter} disabled={busy} className="btn-ghost">
            Invite as writer
          </button>
        )}
        {profile.role !== "editor" && (
          <button onClick={promoteToEditor} disabled={busy} className="btn-ghost">
            Make editor
          </button>
        )}
        {profile.role !== "editor" && (
          <button
            onClick={toggleStatus}
            disabled={busy}
            className={
              profile.status === "active"
                ? "rounded border border-danger/30 px-4 py-2.5 text-sm font-semibold text-danger hover:bg-danger/5"
                : "btn-solid"
            }
          >
            {profile.status === "active" ? "Suspend" : "Reinstate"}
          </button>
        )}
      </div>
    </div>
  );
}
