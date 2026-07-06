import type { ArticleStatus } from "@/types/database";

const LABELS: Record<ArticleStatus, string> = {
  draft: "Draft",
  in_review: "In review",
  published: "Published",
  rejected: "Rejected",
};

export function StatusBadge({ status }: { status: ArticleStatus }) {
  return <span className={`status-pill status-pill--${status}`}>{LABELS[status]}</span>;
}
