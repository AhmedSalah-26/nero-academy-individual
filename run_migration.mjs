import { existsSync, readFileSync, writeFileSync } from 'fs';
import { dirname, resolve } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

const defaultScripts = [
  'database_scripts/000_nasaq_full_database.sql',
];

function loadDotEnv(path) {
  if (!existsSync(path)) return {};

  const content = readFileSync(path, 'utf-8');
  return Object.fromEntries(
    content
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter((line) => line && !line.startsWith('#') && line.includes('='))
      .map((line) => {
        const index = line.indexOf('=');
        const key = line.slice(0, index).trim();
        const value = line.slice(index + 1).trim().replace(/^["']|["']$/g, '');
        return [key, value];
      }),
  );
}

function envValue(env, ...keys) {
  for (const key of keys) {
    if (process.env[key]) return process.env[key];
    if (env[key]) return env[key];
  }
  return '';
}

function projectRefFromUrl(url) {
  try {
    return new URL(url).host.split('.')[0];
  } catch {
    return '';
  }
}

function decodeJwtPayload(token) {
  try {
    const payload = token.split('.')[1];
    const padded = payload.replace(/-/g, '+').replace(/_/g, '/').padEnd(
      Math.ceil(payload.length / 4) * 4,
      '=',
    );
    return JSON.parse(Buffer.from(padded, 'base64').toString('utf-8'));
  } catch {
    return null;
  }
}

function readDartConstant(path, name) {
  if (!existsSync(path)) return '';

  const content = readFileSync(path, 'utf-8');
  const regex = new RegExp(`static\\s+const\\s+String\\s+${name}\\s*=\\s*(['"])([\\s\\S]*?)\\1\\s*;`);
  const match = content.match(regex);
  if (!match) return '';

  return match[2].replace(/\\u([0-9a-fA-F]{4})/g, (_, code) =>
    String.fromCharCode(parseInt(code, 16)),
  );
}

const rootEnv = loadDotEnv(resolve(__dirname, '.env.local'));
const webEnv = loadDotEnv(resolve(__dirname, 'web_app/.env.local'));
const env = { ...webEnv, ...rootEnv };
const constantsPath = resolve(__dirname, 'lib/core/constants/app_constants.dart');

const supabaseUrl = envValue(
  env,
  'SUPABASE_URL',
  'NEXT_PUBLIC_SUPABASE_URL',
  'VITE_SUPABASE_URL',
) || readDartConstant(constantsPath, 'supabaseUrl');
const anonKey = envValue(
  env,
  'SUPABASE_ANON_KEY',
  'NEXT_PUBLIC_SUPABASE_ANON_KEY',
  'VITE_SUPABASE_ANON_KEY',
) || readDartConstant(constantsPath, 'supabaseAnonKey');
const accessToken = envValue(env, 'SUPABASE_ACCESS_TOKEN');
const projectRef = envValue(env, 'SUPABASE_PROJECT_REF') || projectRefFromUrl(supabaseUrl);

const scripts = process.argv.slice(2).length > 0 ? process.argv.slice(2) : defaultScripts;
const sql = scripts
  .map((scriptPath) => {
    const absolutePath = resolve(__dirname, scriptPath);
    if (!existsSync(absolutePath)) {
      throw new Error(`Missing migration file: ${scriptPath}`);
    }

    return [
      `-- ============================================================`,
      `-- ${scriptPath}`,
      `-- ============================================================`,
      readFileSync(absolutePath, 'utf-8'),
    ].join('\n');
  })
  .join('\n\n');

if (!supabaseUrl || !projectRef) {
  throw new Error(
    'Missing SUPABASE_URL/NEXT_PUBLIC_SUPABASE_URL or SUPABASE_PROJECT_REF.',
  );
}

const anonPayload = anonKey ? decodeJwtPayload(anonKey) : null;
if (anonPayload?.ref && anonPayload.ref !== projectRef) {
  console.warn(`WARNING: anon key ref (${anonPayload.ref}) does not match URL/project ref (${projectRef}).`);
}

console.log(`Project: ${projectRef}`);
console.log(`Scripts: ${scripts.join(', ')}`);

if (!accessToken) {
  console.log('\nCannot execute DDL without SUPABASE_ACCESS_TOKEN.');
  if (scripts.length === defaultScripts.length && scripts.every((script, index) => script === defaultScripts[index])) {
    console.log(`Use the existing SQL file: ${resolve(__dirname, defaultScripts[0])}`);
  } else {
    const outputPath = resolve(__dirname, 'database_scripts/generated_migration.sql');
    writeFileSync(outputPath, sql, 'utf-8');
    console.log(`Wrote combined SQL to: ${outputPath}`);
  }
  console.log(`Open SQL Editor: https://supabase.com/dashboard/project/${projectRef}/sql/new`);
  process.exit(2);
}

const response = await fetch(
  `https://api.supabase.com/v1/projects/${projectRef}/database/query`,
  {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ query: sql }),
  },
);

const body = await response.text();
if (!response.ok) {
  console.error(body);
  throw new Error(`Migration failed with HTTP ${response.status}.`);
}

console.log('Migration executed successfully.');
if (body) console.log(body);
