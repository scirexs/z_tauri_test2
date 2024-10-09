#!/bin/sh
# install prerequisites (for windows -> gcc-mingw-w64-x86-64-win32, nsis)
sudo apt update
sudo apt install -y libwebkit2gtk-4.1-dev \
  build-essential \
  curl \
  wget \
  file \
  libxdo-dev \
  libssl-dev \
  libayatana-appindicator3-dev \
  librsvg2-dev \
  gcc-mingw-w64-x86-64-win32 \
  nsis
mkdir ./.cargo
cat << EOF > ./.cargo/config.toml
[target.x86_64-pc-windows-gnu]
linker = "x86_64-w64-mingw32-gcc"
EOF
rustup target add x86_64-pc-windows-gnu
cargo install cargo-edit
cargo install tauri-cli --version "^2.0.0" --locked

# install svelte & set up ssg
npm install create-svelte
node ./.devcontainer/svelte.mjs $1
sed -i '/"dev": "vite dev"/ s/vite dev/vite dev --host/' ./package.json
sed -i '/"preview": "vite preview"/ s/vite preview/vite preview --host/' ./package.json
sed -i '/"strict": true/ a \		"typeRoots": ["./node_modules/@types", "./src/lib/type"],' ./tsconfig.json
sed -i '/ignores:/ i\
		files: ["src/lib/util.ts"],\
		rules: {\
			"@typescript-eslint/no-explicit-any": "off",\
		}\
	},\
	{\
' ./eslint.config.js
sed -i '/^declare global/ i /// <reference types="../lib/type" />' ./src/app.d.ts
rm

npm install --save-dev @sveltejs/adapter-static
sed -i '/^import adapter from/ s:@sveltejs/adapter-auto:@sveltejs/adapter-static:' ./svelte.config.js
cat << EOF | sed -i '/adapter: adapter()/ r /dev/stdin' ./svelte.config.js
    adapter: adapter({
      pages: 'build',
      assets: 'build',
      fallback: undefined,
      precompress: false,
      strict: true
    }),
EOF
sed -i '/adapter: adapter()/ d' ./svelte.config.js
echo 'export const prerender = true;' > ./src/routes/+layout.ts

# install tailwind
npm install --save-dev tailwindcss postcss autoprefixer
npx tailwindcss init -p
sed -i '/content: \[\]/ s:\[\]:\["./src/**/*.{html,js,svelte,ts}", "./lib/style.ts", "./lib/assy/*.svelte"\]:' ./tailwind.config.js
cat << EOF | sed -i '/extend: {}/ r /dev/stdin' ./tailwind.config.js
    extend: {
      colors: {
        canvas: "var(--color-canvas)",
        active: "var(--color-active)",
        inactive: "var(--color-inactive)",
        charline: "var(--color-charline)",
        invalid: "var(--color-invalid)",
      }
    }
EOF
sed -i '/extend: {}/ d' ./tailwind.config.js
cat << EOF > ./src/app.css
@tailwind base;
@tailwind components;
@tailwind utilities;

  :root {
    --color-canvas: #000;
    --color-active: #000;
    --color-inactive: #000;
    --color-charline: #000;
    --color-invalid: #000;
  }
  html {
    font-family: system-ui, ui-sans-serif, -apple-system, "Hiragino Sans", "Yu Gothic UI", "Segoe UI", "Meiryo", sans-serif;
  }
  body {
    background-color: var(--color-canvas);
  }
EOF

# Install tauri
cargo tauri init -A $1 -W $1 -D ../build -P http://localhost:5173 --before-dev-command "npm run dev" --before-build-command "npm run build"
sed -i "/\"identifier\": \"com.tauri.dev\"/ s/com.tauri.dev/dev.scirexs.$1/" ./src-tauri/tauri.conf.json
sed -i '/"csp": null/ s/null/"default-src '\''self'\''"/' ./src-tauri/tauri.conf.json
sed -i '/"version": "0.1.0"/ d' ./src-tauri/tauri.conf.json
sed -i "/\"targets\": \"all\"/ a \    \"copyright\": \"(c) $(date +'%Y') scirexs\"," ./src-tauri/tauri.conf.json
sed -i '/"targets": "all"/ a \    "category": "Utility",' ./src-tauri/tauri.conf.json

sed -i "/^name = \"app\"/ s/app/$1/" ./src-tauri/Cargo.toml
sed -i '/^description = "A Tauri App"/ s/A Tauri App/My tauri application/' ./src-tauri/Cargo.toml
sed -i '/^authors = \["you"\]/ s/you/scirexs/' ./src-tauri/Cargo.toml
sed -i '/^license = ""/ s/""/"MIT OR Apache-2.0"/' ./src-tauri/Cargo.toml
sed -i "/^repository = \"\"/ s#\"\"#\"https://github.com/scirexs/$1\"#" ./src-tauri/Cargo.toml

