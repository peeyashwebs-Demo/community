import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getProfile } from "@/lib/getProfile";

export const dynamic = "force-dynamic";

function slugify(text: string) {
  return (
    text
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/(^-|-$)/g, "") || "untitled"
  );
}

export default async function NewDraftPage() {
  const profile = await getProfile();
  const supabase = createClient();

  const slugBase = `untitled-${Date.now().toString(36)}`;

  const { data, error } = await supabase
    .from("articles")
    .insert({
      title: "",
      slug: slugBase,
      body: "",
      author_id: profile!.id,
      status: "draft",
    })
    .select()
    .single();

  if (error || !data) {
    return (
      <p className="text-danger">Couldn't start a new draft. Refresh and try again.</p>
    );
  }

  redirect(`/writer/${data.id}/edit`);
}
