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
        const key = line.slice(0, index).trim();
        const value = line.slice(index + 1).trim().replace(/^["']|["']$/g, '');
        return [key, value];
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
  console.error('PowerShell example:');
  console.error("$env:SUPABASE_SERVICE_ROLE_KEY='YOUR_SERVICE_ROLE_KEY'; node scripts/reset_demo_users.mjs");
  process.exit(1);
}

const headers = {
  apikey: serviceRoleKey,
  Authorization: `Bearer ${serviceRoleKey}`,
  'Content-Type': 'application/json',
};

const demoUsers = [
  {
    email: 'admin@nasaq.dev',
    password: 'Nasaq@123456',
    name: 'Nasaq Admin',
    role: 'admin',
  },
  {
    email: 'student@nasaq.dev',
    password: 'Nasaq@123456',
    name: 'Nasaq Student',
    role: 'student',
  },
  {
    email: 'teacher@nasaq.dev',
    password: 'Nasaq@123456',
    name: 'Nasaq Teacher',
    role: 'instructor',
  },
];

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

async function requestAllowingNotFound(path, options = {}) {
  const response = await fetch(`${supabaseUrl}${path}`, {
    ...options,
    headers: { ...headers, ...(options.headers ?? {}) },
  });
  const text = await response.text();

  if (response.status === 404) return null;

  if (!response.ok) {
    throw new Error(`${options.method ?? 'GET'} ${path} failed (${response.status}): ${text}`);
  }

  return text ? JSON.parse(text) : null;
}

async function listAllUsers() {
  const users = [];
  let page = 1;

  try {
    while (true) {
      const body = await request(`/auth/v1/admin/users?page=${page}&per_page=1000`);
      const batch = body.users ?? [];
      users.push(...batch);
      if (batch.length < 1000) break;
      page += 1;
    }
  } catch (error) {
    console.warn(`Auth user listing failed: ${error.message}`);
    console.warn('Falling back to public.profiles ids.');
    return request('/rest/v1/profiles?select=id,email');
  }

  return users;
}

async function deleteUser(user) {
  try {
    await requestAllowingNotFound(`/auth/v1/admin/users/${user.id}`, { method: 'DELETE' });
    console.log(`Deleted auth user ${user.email ?? user.id}`);
  } catch (error) {
    console.warn(`Auth delete failed for ${user.email ?? user.id}: ${error.message}`);
    await request(`/rest/v1/profiles?id=eq.${user.id}`, { method: 'DELETE' });
    console.warn(`Deleted profile fallback ${user.email ?? user.id}`);
  }
}

async function createUser(user) {
  const body = await request('/auth/v1/admin/users', {
    method: 'POST',
    body: JSON.stringify({
      email: user.email,
      password: user.password,
      email_confirm: true,
      user_metadata: {
        name: user.name,
        full_name: user.name,
        role: user.role,
      },
    }),
  });

  const authUser = body.user ?? body;
  await request('/rest/v1/profiles?on_conflict=id', {
    method: 'POST',
    headers: { Prefer: 'resolution=merge-duplicates,return=representation' },
    body: JSON.stringify({
      id: authUser.id,
      email: user.email,
      name: user.name,
      role: user.role,
      is_active: true,
      is_banned: false,
      is_verified_instructor: user.role === 'instructor',
    }),
  });

  if (user.role === 'instructor') {
    const teachers = await request('/rest/v1/teachers?on_conflict=profile_id', {
      method: 'POST',
      headers: { Prefer: 'resolution=merge-duplicates,return=representation' },
      body: JSON.stringify({
        profile_id: authUser.id,
        display_name: user.name,
        is_active: true,
      }),
    });

    const teacherId = teachers?.[0]?.id;
    if (teacherId) {
      await request('/rest/v1/teacher_settings?on_conflict=teacher_id', {
        method: 'POST',
        headers: { Prefer: 'resolution=merge-duplicates' },
        body: JSON.stringify({ teacher_id: teacherId }),
      });
      await request('/rest/v1/teacher_themes?on_conflict=teacher_id', {
        method: 'POST',
        headers: { Prefer: 'resolution=merge-duplicates,return=representation' },
        body: JSON.stringify({
          teacher_id: teacherId,
          primary_color: '#20E5DC',
          secondary_color: '#117CFF',
          background_color: '#01060B',
          logo_url: null,
          welcome_text: null,
        }),
      });
    }
  }

  console.log(`Created ${user.role}: ${user.email} / ${user.password}`);
}

async function linkDefaultStudentToTeacher() {
  const profiles = await request(
    '/rest/v1/profiles?select=id,email&email=in.(student@nasaq.dev,teacher@nasaq.dev)',
  );
  const student = profiles.find((profile) => profile.email === 'student@nasaq.dev');
  const teacherProfile = profiles.find((profile) => profile.email === 'teacher@nasaq.dev');
  if (!student || !teacherProfile) return;

  const teachers = await request(
    `/rest/v1/teachers?select=id&profile_id=eq.${teacherProfile.id}`,
  );
  const teacherId = teachers[0]?.id;
  if (!teacherId) return;

  await request(`/rest/v1/profiles?id=eq.${student.id}`, {
    method: 'PATCH',
    body: JSON.stringify({ active_teacher_id: teacherId }),
  });
  await request('/rest/v1/student_teacher_links?on_conflict=student_id,teacher_id', {
    method: 'POST',
    headers: { Prefer: 'resolution=merge-duplicates' },
    body: JSON.stringify({
      student_id: student.id,
      teacher_id: teacherId,
      is_active: true,
    }),
  });
}

const users = await listAllUsers();
console.log(`Found ${users.length} auth user(s).`);

for (const user of users) {
  await deleteUser(user);
}

for (const user of demoUsers) {
  await createUser(user);
}

await linkDefaultStudentToTeacher();

console.log('\nDone. Demo accounts:');
for (const user of demoUsers) {
  console.log(`${user.role.padEnd(10)} ${user.email}  ${user.password}`);
}
