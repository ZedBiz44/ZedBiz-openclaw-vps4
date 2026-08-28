import { build } from 'esbuild';
import { readFileSync } from 'fs';

async function main() {
  const pkg = JSON.parse(readFileSync('package.json', 'utf8'));

  await build({
    entryPoints: ['src/index.ts', 'src/advanced-server.ts', 'src/team-server.ts', 'src/smoke-test.ts', 'src/catalog-test.ts'],
    bundle: true,
    platform: 'node',
    target: 'node24',
    format: 'esm',
    outdir: 'dist',
    define: {
      __VERSION__: JSON.stringify(pkg.version),
      'process.env.NODE_ENV': JSON.stringify('production')
    },
    banner: {
      js: `// Asana MCP Server v${pkg.version}\n`
    },
    external: [
      // Node.js built-in modules that should not be bundled
      'url',
      'http',
      'https',
      'stream',
      'zlib',
      'util',
      'events',
      'buffer',
      'querystring',
      'asana',
      'express',
      'jsdom',
    ]
  });
}

main().catch(console.error);
