import { existsSync, readFileSync } from 'fs';
import { resolve } from 'path';
import { fileURLToPath } from 'url';

const root = resolve(fileURLToPath(new URL('..', import.meta.url)));

function loadDotEnv(path) {
  if (!existsSync(path)) return {};
  return Object.fromEntries(
    readFileSync(path, 'utf8')
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter((line) => line && !line.startsWith('#') && line.includes('='))
      .map((line) => {
        const index = line.indexOf('=');
        return [
          line.slice(0, index).trim(),
          line.slice(index + 1).trim().replace(/^["']|["']$/g, ''),
        ];
      }),
  );
}

function readDartConstant(path, name) {
  if (!existsSync(path)) return '';
  const content = readFileSync(path, 'utf8');
  const regex = new RegExp(`static\\s+const\\s+String\\s+${name}\\s*=\\s*(['"])([\\s\\S]*?)\\1\\s*;`);
  return content.match(regex)?.[2] ?? '';
}

const env = { ...loadDotEnv(resolve(root, '.env.local')), ...process.env };
const constantsPath = resolve(root, 'lib/core/constants/app_constants.dart');
const supabaseUrl =
  env.SUPABASE_URL ||
  env.NEXT_PUBLIC_SUPABASE_URL ||
  readDartConstant(constantsPath, 'supabaseUrl');
const serviceRoleKey = env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !serviceRoleKey) {
  console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY.');
  process.exit(1);
}

const headers = {
  apikey: serviceRoleKey,
  Authorization: `Bearer ${serviceRoleKey}`,
  'Content-Type': 'application/json',
};

const keepEmails = ['admin@nasaq.dev', 'student@nasaq.dev', 'teacher@nasaq.dev'];

async function request(path, options = {}) {
  const response = await fetch(`${supabaseUrl}${path}`, {
    ...options,
    headers: { ...headers, ...(options.headers ?? {}) },
  });
  const text = await response.text();
  const body = text ? JSON.parse(text) : null;
  if (!response.ok) {
    throw new Error(`${options.method ?? 'GET'} ${path} failed (${response.status}): ${text}`);
  }
  return body;
}

async function requestOptional(path, options = {}) {
  try {
    return await request(path, options);
  } catch (error) {
    const message = error.message;
    if (
      message.includes('PGRST204') ||
      message.includes('PGRST205') ||
      message.includes('Could not find') ||
      message.includes('does not exist')
    ) {
      console.warn(`Skipped ${path}: ${message}`);
      return null;
    }
    throw error;
  }
}

function inList(values) {
  return `(${values.join(',')})`;
}

async function deleteWhereNotIn(table, column, keepValues) {
  if (keepValues.length === 0) return 0;
  const result = await requestOptional(`/rest/v1/${table}?${column}=not.in.${inList(keepValues)}`, {
    method: 'DELETE',
    headers: { Prefer: 'return=representation' },
  });
  const count = Array.isArray(result) ? result.length : 0;
  if (count) console.log(`Deleted ${count} from ${table}.${column}`);
  return count;
}

async function nullWhereNotIn(table, column, keepValues) {
  if (keepValues.length === 0) return 0;
  const result = await requestOptional(`/rest/v1/${table}?${column}=not.in.${inList(keepValues)}`, {
    method: 'PATCH',
    headers: { Prefer: 'return=representation' },
    body: JSON.stringify({ [column]: null }),
  });
  const count = Array.isArray(result) ? result.length : 0;
  if (count) console.log(`Cleared ${count} from ${table}.${column}`);
  return count;
}

const profiles = await request(
  `/rest/v1/profiles?select=id,email,role&email=in.(${keepEmails.join(',')})`,
);

const missing = keepEmails.filter(
  (email) => !profiles.some((profile) => profile.email === email),
);
if (missing.length) {
  throw new Error(`Missing required demo profiles: ${missing.join(', ')}`);
}

const keepProfileIds = profiles.map((profile) => profile.id);
const teacherProfile = profiles.find((profile) => profile.email === 'teacher@nasaq.dev');
const teachers = await request(
  `/rest/v1/teachers?select=id,profile_id&profile_id=eq.${teacherProfile.id}`,
);
const keepTeacherIds = teachers.map((teacher) => teacher.id);

console.log(`Keeping profiles: ${keepProfileIds.join(', ')}`);
console.log(`Keeping teachers: ${keepTeacherIds.join(', ') || '(none)'}`);

const deleteProfileRefs = [
  ['direct_message_reactions', 'user_id'],
  ['message_reactions', 'user_id'],
  ['qa_answer_upvotes', 'user_id'],
  ['announcement_reads', 'user_id'],
  ['coupon_usages', 'user_id'],
  ['lesson_progress', 'user_id'],
  ['cart_items', 'user_id'],
  ['wishlist', 'user_id'],
  ['certificates', 'user_id'],
  ['notes', 'user_id'],
  ['bookmarks', 'user_id'],
  ['quiz_attempts', 'user_id'],
  ['notifications', 'user_id'],
  ['user_settings', 'user_id'],
  ['student_teacher_links', 'student_id'],
  ['payment_requests', 'student_id'],
  ['parent_enrollments', 'user_id'],
  ['manual_purchase_request_items', 'user_id'],
  ['direct_messages', 'sender_id'],
  ['direct_messages', 'receiver_id'],
  ['messages', 'user_id'],
  ['conversation_participants', 'user_id'],
  ['conversations', 'created_by'],
  ['withdraw_requests', 'user_id'],
  ['qa_answers', 'user_id'],
  ['qa_questions', 'user_id'],
  ['course_reviews', 'user_id'],
  ['course_reports', 'user_id'],
  ['review_reports', 'user_id'],
  ['enrollments', 'user_id'],
  ['enrollments', 'teacher_id'],
  ['instructor_earnings', 'teacher_id'],
  ['announcements', 'teacher_id'],
  ['coupons', 'teacher_id'],
  ['courses', 'teacher_id'],
  ['teachers', 'profile_id'],
];

const deleteTeacherRefs = [
  ['student_teacher_links', 'teacher_id'],
  ['payment_requests', 'teacher_id'],
  ['parent_enrollments', 'teacher_id'],
  ['manual_purchase_request_items', 'teacher_id'],
  ['courses', 'teacher_id'],
];

const nullableProfileRefs = [
  ['withdraw_requests', 'admin_id'],
  ['course_reports', 'admin_id'],
  ['review_reports', 'admin_id'],
  ['payment_requests', 'reviewed_by'],
  ['manual_purchase_request_items', 'teacher_id'],
];

let deleted = 0;
let cleared = 0;

for (const [table, column] of deleteProfileRefs) {
  deleted += await deleteWhereNotIn(table, column, keepProfileIds);
}

for (const [table, column] of deleteTeacherRefs) {
  deleted += await deleteWhereNotIn(table, column, keepTeacherIds);
}

for (const [table, column] of nullableProfileRefs) {
  cleared += await nullWhereNotIn(table, column, keepProfileIds);
}

deleted += await deleteWhereNotIn('profiles', 'id', keepProfileIds);

const remainingProfiles = await request('/rest/v1/profiles?select=email,role,name&order=email.asc');
const remainingTeachers = await request('/rest/v1/teachers?select=id,display_name,is_active');

console.log(`\nDeleted rows: ${deleted}`);
console.log(`Cleared nullable refs: ${cleared}`);
console.log('Remaining profiles:');
console.log(JSON.stringify(remainingProfiles, null, 2));
console.log('Remaining teachers:');
console.log(JSON.stringify(remainingTeachers, null, 2));
