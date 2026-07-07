import Link from "next/link";

const TABS = [
  { href: "/admin", label: "Dashboard" },
  { href: "/admin/review", label: "Review queue" },
  { href: "/admin/writers", label: "Writers" },
  { href: "/admin/comments", label: "Comments" },
  { href: "/admin/feedback", label: "Feedback" },
];

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="mx-auto max-w-6xl px-6 py-10 sm:px-10">
      <p className="mono-label mb-1 text-signal">Admin</p>
      <h1 className="mb-6 font-display text-3xl font-semibold">Newsroom control</h1>
      <nav className="mb-10 flex gap-1 overflow-x-auto border-b border-rule">
        {TABS.map((t) => (
          <Link
            key={t.href}
            href={t.href}
            className="whitespace-nowrap px-4 py-2.5 text-sm font-medium text-ink-muted hover:text-ink"
          >
            {t.label}
          </Link>
        ))}
      </nav>
      {children}
    </div>
  );
}
