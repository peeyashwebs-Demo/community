import { createClient } from "@/lib/supabase/server";
import type { Feedback } from "@/types/database";

export const dynamic = "force-dynamic";

export default async function AdminFeedbackPage() {
  const supabase = createClient();
  const { data } = await supabase
    .from("feedback")
    .select("*")
    .order("created_at", { ascending: false });

  const items = (data ?? []) as Feedback[];

  if (items.length === 0) {
    return <p className="font-body italic text-ink-muted">No feedback submitted yet.</p>;
  }

  return (
    <div className="divide-y divide-rule border-y border-rule">
      {items.map((f) => (
        <div key={f.id} className="py-5">
          <div className="mb-2 flex items-center justify-between">
            <p className="font-display font-medium">{f.name}</p>
            {f.rating && (
              <span className="text-signal">{"★".repeat(f.rating)}{"☆".repeat(5 - f.rating)}</span>
            )}
          </div>
          <p className="mb-2 text-[15px] leading-relaxed">{f.message}</p>
          <p className="mono-label">
            {f.email ?? "No email"} · {new Date(f.created_at).toLocaleDateString()}
          </p>
        </div>
      ))}
    </div>
  );
}
