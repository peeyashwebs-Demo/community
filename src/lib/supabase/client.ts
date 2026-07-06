import { createBrowserClient } from "@supabase/ssr";
import type { Database } from "@/types/database";

/**
 * Use this client in Client Components ("use client").
 * It reads the session from the browser cookies set by the server client.
 */
export function createClient() {
  return createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}
