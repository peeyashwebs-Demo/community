/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        paper: "#F5F4EF",
        ink: "#14171C",
        "ink-muted": "#6B6860",
        rule: "#DEDACF",
        signal: "#B23A2E",
        "signal-dark": "#98301F",
        verified: "#2F6F5E",
        pending: "#A67C2E",
        danger: "#A32B2B",
        surface: "#FFFFFF",
      },
      fontFamily: {
        display: ["var(--font-fraunces)", "serif"],
        body: ["var(--font-source-serif)", "serif"],
        sans: ["var(--font-inter)", "sans-serif"],
        mono: ["var(--font-plex-mono)", "monospace"],
      },
      borderRadius: {
        DEFAULT: "2px",
      },
      maxWidth: {
        article: "700px",
      },
    },
  },
  plugins: [],
};
