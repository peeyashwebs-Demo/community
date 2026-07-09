"use client";

import { useRef, useState } from "react";
import type { Editor } from "@tiptap/react";
import { createClient } from "@/lib/supabase/client";
import {
  Bold,
  Italic,
  Underline as UnderlineIcon,
  Strikethrough,
  List,
  ListOrdered,
  Quote,
  Heading2,
  Heading3,
  Link as LinkIcon,
  ImageIcon,
  Loader2,
  Undo2,
  Redo2,
} from "lucide-react";

function ToolbarButton({
  onClick,
  active,
  disabled,
  label,
  children,
}: {
  onClick: () => void;
  active?: boolean;
  disabled?: boolean;
  label: string;
  children: React.ReactNode;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      title={label}
      aria-label={label}
      className={`flex h-8 w-8 flex-shrink-0 items-center justify-center rounded transition-colors sm:h-9 sm:w-9 ${
        active ? "bg-ink text-paper" : "text-ink-muted hover:bg-paper hover:text-ink"
      } disabled:opacity-30`}
    >
      {children}
    </button>
  );
}

function Divider() {
  return <div className="mx-0.5 h-5 w-px flex-shrink-0 bg-rule sm:mx-1" />;
}

export function EditorToolbar({
  editor,
  articleId,
  authorId,
}: {
  editor: Editor | null;
  articleId: string;
  authorId: string;
}) {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(false);
  const supabase = createClient();

  if (!editor) return null;

  function setLink() {
    const previousUrl = editor!.getAttributes("link").href;
    const url = window.prompt("Link URL", previousUrl || "https://");
    if (url === null) return;
    if (url === "") {
      editor!.chain().focus().extendMarkRange("link").unsetLink().run();
      return;
    }
    editor!.chain().focus().extendMarkRange("link").setLink({ href: url }).run();
  }

  function openImagePicker() {
    fileInputRef.current?.click();
  }

  async function handleImageFile(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    // Reset immediately so choosing the same file again still fires onChange.
    e.target.value = "";
    if (!file) return;

    setUploading(true);

    const path = `${authorId}/${articleId}-inline-${Date.now()}-${file.name}`;
    const { error } = await supabase.storage.from("covers").upload(path, file);

    if (error) {
      window.alert("Couldn't upload that image — try again.");
      setUploading(false);
      return;
    }

    const { data } = supabase.storage.from("covers").getPublicUrl(path);
    editor!.chain().focus().setImage({ src: data.publicUrl }).run();
    setUploading(false);
  }

  return (
    <div className="flex flex-wrap items-center gap-0.5 border-b border-rule bg-paper/60 px-2 py-2 sm:gap-1 sm:px-3">
      <input
        ref={fileInputRef}
        type="file"
        accept="image/*"
        onChange={handleImageFile}
        className="hidden"
      />

      <ToolbarButton
        label="Bold"
        active={editor.isActive("bold")}
        onClick={() => editor.chain().focus().toggleBold().run()}
      >
        <Bold size={16} />
      </ToolbarButton>
      <ToolbarButton
        label="Italic"
        active={editor.isActive("italic")}
        onClick={() => editor.chain().focus().toggleItalic().run()}
      >
        <Italic size={16} />
      </ToolbarButton>
      <ToolbarButton
        label="Underline"
        active={editor.isActive("underline")}
        onClick={() => editor.chain().focus().toggleUnderline().run()}
      >
        <UnderlineIcon size={16} />
      </ToolbarButton>
      <ToolbarButton
        label="Strikethrough"
        active={editor.isActive("strike")}
        onClick={() => editor.chain().focus().toggleStrike().run()}
      >
        <Strikethrough size={16} />
      </ToolbarButton>

      <Divider />

      <ToolbarButton
        label="Heading"
        active={editor.isActive("heading", { level: 2 })}
        onClick={() => editor.chain().focus().toggleHeading({ level: 2 }).run()}
      >
        <Heading2 size={16} />
      </ToolbarButton>
      <ToolbarButton
        label="Subheading"
        active={editor.isActive("heading", { level: 3 })}
        onClick={() => editor.chain().focus().toggleHeading({ level: 3 }).run()}
      >
        <Heading3 size={16} />
      </ToolbarButton>

      <Divider />

      <ToolbarButton
        label="Bullet list"
        active={editor.isActive("bulletList")}
        onClick={() => editor.chain().focus().toggleBulletList().run()}
      >
        <List size={16} />
      </ToolbarButton>
      <ToolbarButton
        label="Numbered list"
        active={editor.isActive("orderedList")}
        onClick={() => editor.chain().focus().toggleOrderedList().run()}
      >
        <ListOrdered size={16} />
      </ToolbarButton>
      <ToolbarButton
        label="Quote"
        active={editor.isActive("blockquote")}
        onClick={() => editor.chain().focus().toggleBlockquote().run()}
      >
        <Quote size={16} />
      </ToolbarButton>

      <Divider />

      <ToolbarButton label="Link" active={editor.isActive("link")} onClick={setLink}>
        <LinkIcon size={16} />
      </ToolbarButton>
      <ToolbarButton label="Upload image" disabled={uploading} onClick={openImagePicker}>
        {uploading ? <Loader2 size={16} className="animate-spin" /> : <ImageIcon size={16} />}
      </ToolbarButton>

      <Divider />

      <ToolbarButton
        label="Undo"
        disabled={!editor.can().undo()}
        onClick={() => editor.chain().focus().undo().run()}
      >
        <Undo2 size={16} />
      </ToolbarButton>
      <ToolbarButton
        label="Redo"
        disabled={!editor.can().redo()}
        onClick={() => editor.chain().focus().redo().run()}
      >
        <Redo2 size={16} />
      </ToolbarButton>
    </div>
  );
}
