import type { Metadata } from "next";
import { Fraunces, Source_Serif_4, Inter, IBM_Plex_Mono } from "next/font/google";
import "./globals.css";
import { Masthead } from "@/components/Masthead";
import { getProfile } from "@/lib/getProfile";

const fraunces = Fraunces({
  subsets: ["latin"],
  variable: "--font-fraunces",
  weight: ["400", "500", "600", "700"],
});
const sourceSerif = Source_Serif_4({
  subsets: ["latin"],
  variable: "--font-source-serif",
  weight: ["400", "500"],
});
const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
  weight: ["400", "500", "600"],
});
const plexMono = IBM_Plex_Mono({
  subsets: ["latin"],
  variable: "--font-plex-mono",
  weight: ["400", "500"],
});

export const metadata: Metadata = {
  title: "The Gist — Community News & Gist Platform",
  description: "A community newsroom: writer drafts, editorial review, public stories.",
};

export default async function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const profile = await getProfile();

  return (
    <html lang="en">
      <body
        className={`${fraunces.variable} ${sourceSerif.variable} ${inter.variable} ${plexMono.variable}`}
      >
        <Masthead profile={profile} />
        {children}
      </body>
    </html>
  );
}
