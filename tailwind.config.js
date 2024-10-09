/** @type {import('tailwindcss').Config} */
export default {
  content: ["./src/**/*.{html,js,svelte,ts}", "./lib/style.ts", "./lib/assy/*.svelte"],
  theme: {
    extend: {
      colors: {
        canvas: "var(--color-canvas)",
        active: "var(--color-active)",
        inactive: "var(--color-inactive)",
        charline: "var(--color-charline)",
        invalid: "var(--color-invalid)",
      }
    }
  },
  plugins: [],
}

