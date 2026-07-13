import { existsSync, readdirSync, readFileSync, statSync, writeFileSync } from 'fs';
import { join, relative } from 'path';

const roots = process.argv
  .slice(2)
  .filter((arg) => arg !== '--write');
const write = process.argv.includes('--write');
const scanRoots = roots.length > 0 ? roots : ['lib', 'supabase', 'database_scripts', 'scripts'];
const extensions = new Set(['.dart', '.sql', '.ts', '.js', '.mjs']);

const replacements = [
  ['instructor_id', 'teacher_id'],
  ['instructorId', 'teacherId'],
  ['InstructorId', 'TeacherId'],
  ['p_instructor_id', 'p_teacher_id'],
  ['v_instructor_id', 'v_teacher_id'],
  ['from_instructor_id', 'from_teacher_id'],
];

function shouldSkip(path) {
  return path.includes(`${join('build')}`) ||
    path.includes(`${join('.dart_tool')}`) ||
    path.includes(`${join('.git')}`);
}

function extensionOf(path) {
  const index = path.lastIndexOf('.');
  return index === -1 ? '' : path.slice(index);
}

function walk(path, files = []) {
  if (!existsSync(path) || shouldSkip(path)) return files;

  const stat = statSync(path);
  if (stat.isDirectory()) {
    for (const entry of readdirSync(path)) {
      walk(join(path, entry), files);
    }
    return files;
  }

  if (stat.isFile() && extensions.has(extensionOf(path))) {
    files.push(path);
  }
  return files;
}

let changed = 0;
for (const root of scanRoots) {
  for (const file of walk(root)) {
    const original = readFileSync(file, 'utf8');
    let next = original;
    for (const [from, to] of replacements) {
      next = next.split(from).join(to);
    }

    if (next === original) continue;
    changed += 1;
    console.log(`${write ? 'updated' : 'would update'} ${relative(process.cwd(), file)}`);
    if (write) {
      writeFileSync(file, next, 'utf8');
    }
  }
}

console.log(`${write ? 'Updated' : 'Would update'} ${changed} file(s).`);
