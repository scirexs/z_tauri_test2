import { create } from "create-svelte";

async function createSvelteProject() {
  await create(".", {
    name: process.argv[2],
    template: "skeleton",
    types: "typescript",
    prettier: true,
    eslint: true,
    playwright: true,
    vitest: false,
    svelte5: true
  });
}

createSvelteProject();

