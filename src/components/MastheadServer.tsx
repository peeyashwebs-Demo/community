import { Masthead } from "@/components/Masthead";
import { getProfile } from "@/lib/getProfile";

export async function MastheadServer() {
  const profile = await getProfile();
  return <Masthead profile={profile} />;
}
