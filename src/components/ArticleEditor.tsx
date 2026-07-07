"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { useEditor, EditorContent } from "@tiptap/react";
import StarterKit from "@tiptap/starter-kit";
import Placeholder from "@tiptap/extension-placeholder";
import TiptapImage from "@tiptap/extension-image";
import TiptapLink from "@tiptap/extension-link";
import TiptapUnderline from "@tiptap/extension-underline";
import { createClient } from "@/lib/supabase/client";
import { StatusBadge } from "@/components/StatusBadge";
import { EditorToolbar } from "@/components/EditorToolbar";
import type { Article, Category } from "@/types/database";

type SaveState = "saved" | "saving" | "error";

function slugify(text: string) {
  return (
    text
      .toLowerCase()
      .trim()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/(^-|-$)/g, "") || "untitled"
  );
}

export function ArticleEditor({
  article,
  categories,
}: {
  article: Article;
  categories: Category[];
}) {
  const supabase = createClient();
  const router = useRouter();

  const [title, setTitle] = useState(article.title);
  const [categoryId, setCategoryId] = useState(article.category_id ?? "");
  const [coverUrl, setCoverUrl] = useState(article.cover_image_url ?? "");
  const [saveState, setSaveState] = useState<SaveState>("saved");
  const [uploading, setUploading] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  const canEdit = article.status === "draft" || article.status === "rejected";
  const saveTimer = useRef<ReturnType<typeof setTimeout>>();

  const editor = useEditor({
    extensions: [
      StarterKit,
      Placeholder.configure({ placeholder: "Start writing your story…" }),
      TiptapImage,
      TiptapUnderline,
      TiptapLink.configure({
        openOnClick: false,
        HTMLAttributes: { rel: "noopener noreferrer" },
      }),
    ],
    content: article.body,
    editable: canEdit,
    editorProps: {
      attributes: {
        class: "prose-article min-h-[400px] outline-none",
      },
    },
    onUpdate: () => scheduleSave(),
  });

  const scheduleSave = useCallback(() => {
    if (!canEdit) return;
    setSaveState("saving");
    if (saveTimer.current) clearTimeout(saveTimer.current);
    saveTimer.current = setTimeout(save, 900);
  }, [title, categoryId, coverUrl]); // eslint-disable-line react-hooks/exhaustive-deps

  async function save() {
    if (!editor) return;
    const body = editor.getHTML();
    const { error } = await supabase
      .from("articles")
      .update({
        title,
        body,
        category_id: categoryId || null,
        cover_image_url: coverUrl || null,
        slug: title ? `${slugify(title)}-${article.id.slice(0, 6)}` : article.slug,
      })
      .eq("id", article.id);

    setSaveState(error ? "error" : "saved");
  }

  // Autosave whenever title/category/cover changes too, not just editor body.
  useEffect(() => {
    scheduleSave();
    return () => {
      if (saveTimer.current) clearTimeout(saveTimer.current);
    };
  }, [title, categoryId, coverUrl]); // eslint-disable-line react-hooks/exhaustive-deps

  async function handleCoverUpload(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploading(true);

    const path = `${article.author_id}/${article.id}-${Date.now()}-${file.name}`;
    const { error } = await supabase.storage.from("covers").upload(path, file, {
      upsert: true,
    });

    if (!error) {
      const { data } = supabase.storage.from("covers").getPublicUrl(path);
      setCoverUrl(data.publicUrl);
    }
    setUploading(false);
  }

  async function handleSubmitForReview() {
    setSubmitting(true);
    await save(); // flush any pending changes first
    const { error } = await supabase
      .from("articles")
      .update({ status: "in_review" })
      .eq("id", article.id);
    setSubmitting(false);
    if (!error) router.push("/writer");
  }

  return (
    <div className="mx-auto max-w-3xl px-6 py-10 sm:px-10">
      <div className="mb-8 flex items-center justify-between">
        <StatusBadge status={article.status} />
        <span className="mono-label">
          {saveState === "saving" && "Saving…"}
          {saveState === "saved" && "Saved"}
          {saveState === "error" && <span className="text-danger">Couldn't save</span>}
        </span>
      </div>

      {article.status === "rejected" && article.review_note && (
        <div className="mb-8 rounded border border-danger/30 bg-[#FBEAE7] p-4">
          <p className="mono-label mb-1.5 text-danger">Editor feedback</p>
          <p className="text-sm text-ink">{article.review_note}</p>
        </div>
      )}

      {article.status === "in_review" && (
        <div className="mb-8 rounded border border-pending/30 bg-surface p-4 text-sm text-ink-muted">
          This story is with an editor for review. You'll see their decision here.
        </div>
      )}

      <input
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        disabled={!canEdit}
        placeholder="Your headline"
        className="mb-6 w-full border-none bg-transparent font-display text-2xl font-semibold leading-tight outline-none placeholder:text-ink-muted/40 disabled:opacity-70 sm:text-4xl"
      />

      <div className="mb-6 flex flex-wrap gap-4">
        <div>
          <label className="mono-label mb-1.5 block">Category</label>
          <select
            value={categoryId}
            onChange={(e) => setCategoryId(e.target.value)}
            disabled={!canEdit}
            className="rounded border border-rule bg-surface px-3 py-2 text-sm outline-none focus:border-ink"
          >
            <option value="">Uncategorized</option>
            {categories.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
        </div>

        <div>
          <label className="mono-label mb-1.5 block">Cover image</label>
          <input
            type="file"
            accept="image/*"
            disabled={!canEdit || uploading}
            onChange={handleCoverUpload}
            className="text-sm"
          />
        </div>
      </div>

      {coverUrl && (
        <img src={coverUrl} alt="" className="mb-8 aspect-video w-full rounded object-cover" />
      )}

      <div className="mb-10 overflow-hidden rounded border border-rule bg-surface">
        {canEdit && <EditorToolbar editor={editor} />}
        <div className="p-6">
          <EditorContent editor={editor} />
        </div>
      </div>

      {canEdit && (
        <button
          onClick={handleSubmitForReview}
          disabled={submitting || !title.trim()}
          className="btn-solid disabled:opacity-50"
        >
          {submitting ? "Submitting…" : "Submit for review"}
        </button>
      )}
    </div>
  );
}
