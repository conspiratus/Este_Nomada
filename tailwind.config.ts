import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        sand: {
          50: "#faf8f5",
          100: "#f5f0e8",
          200: "#e8ddd0",
          300: "#d9c5b0",
          400: "#c8a88a",
          500: "#b8906f",
          600: "#a67d5f",
          700: "#8a6750",
          800: "#715546",
          900: "#5d463b",
        },
        saffron: {
          50: "#fff8ed",
          100: "#ffeed4",
          200: "#ffd9a8",
          300: "#ffbe71",
          400: "#ff9a38",
          500: "#ff7a11",
          600: "#f05d07",
          700: "#c74608",
          800: "#9e380f",
          900: "#7f3010",
        },
        warm: {
          50: "#faf7f4",
          100: "#f4ede6",
          200: "#e7d8cc",
          300: "#d6bdaa",
          400: "#c19d82",
          500: "#b08566",
          600: "#a17256",
          700: "#855c49",
          800: "#6d4d40",
          900: "#5a4036",
        },
        charcoal: {
          50: "#f6f6f6",
          100: "#e7e7e7",
          200: "#d1d1d1",
          300: "#b0b0b0",
          400: "#888888",
          500: "#6d6d6d",
          600: "#5d5d5d",
          700: "#4f4f4f",
          800: "#454545",
          900: "#3d3d3d",
        },
      },
      fontFamily: {
        sans: ["var(--font-inter)", "system-ui", "sans-serif"],
      },
    },
  },
  plugins: [],
};
export default config;




