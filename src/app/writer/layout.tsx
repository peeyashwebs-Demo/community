import Link from "next/link";

export default function WriterLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="mx-auto max-w-5xl px-6 py-10 sm:px-10">
      <div className="mb-8 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <p className="mono-label mb-1 text-signal">Writer workspace</p>
          <h1 className="font-display text-3xl font-semibold">Your stories</h1>
        </div>
        <Link href="/writer/new" className="btn-solid self-start sm:self-auto">
          New draft
        </Link>
      </div>
      {children}
    </div>
  );
}
