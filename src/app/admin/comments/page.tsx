import { createClient } from "@/lib/supabase/server";
import { attachAuthors } from "@/lib/relations";
import { CommentModerationRow } from "@/components/CommentModerationRow";
import type { Comment } from "@/types/database";

export const dynamic = "force-dynamic";

export default async function AdminCommentsPage() {
  const supabase = createClient();
  const { data } = await supabase
    .from("comments")
    .select("*")
    .neq("status", "deleted")
    .order("created_at", { ascending: false })
    .limit(100);

  const comments = await attachAuthors(supabase, (data ?? []) as Comment[]);

  if (comments.length === 0) {
    return <p className="font-body italic text-ink-muted">No comments yet.</p>;
  }

  return (
    <div className="border-t border-rule">
      {comments.map((c) => (
        <CommentModerationRow key={c.id} comment={c} />
      ))}
    </div>
  );
}
