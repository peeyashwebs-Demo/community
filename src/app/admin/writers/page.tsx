import { createClient } from "@/lib/supabase/server";
import { WriterRow } from "@/components/WriterRow";
import type { Profile } from "@/types/database";

export const dynamic = "force-dynamic";

export default async function AdminWritersPage() {
  const supabase = createClient();
  const { data } = await supabase.from("profiles").select("*").order("created_at", { ascending: false });
  const profiles = (data ?? []) as Profile[];

  return (
    <div>
      <p className="mb-6 max-w-xl text-sm text-ink-muted">
        Invite any reader to become a writer, or suspend an account. Suspending blocks both
        commenting and publishing immediately.
      </p>
      <div className="border-t border-rule">
        {profiles.map((p) => (
          <WriterRow key={p.id} profile={p} />
        ))}
      </div>
    </div>
  );
}
