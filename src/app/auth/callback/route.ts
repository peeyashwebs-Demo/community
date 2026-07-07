import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET(request: Request) {
  const requestUrl = new URL(request.url);
  const code = requestUrl.searchParams.get("code");

  if (code) {
    const supabase = createClient();
    const { error } = await supabase.auth.exchangeCodeForSession(code);

    if (error) {
      return NextResponse.redirect(`${requestUrl.origin}/auth/confirmed?status=error`);
    }

    return NextResponse.redirect(`${requestUrl.origin}/auth/confirmed?status=success`);
  }

  // No code present — either an expired/reused link or someone hit this URL directly.
  return NextResponse.redirect(`${requestUrl.origin}/auth/confirmed?status=error`);
}
