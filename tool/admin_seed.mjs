// Headless registrar import + account activation, run with the developer's
// Firebase CLI credentials (no service-account key needed). Mirrors
// lib/services/seed_service.dart, and additionally sets the `role` JWT claim.
//
//   cd functions && npm install        # provides firebase-admin
//   node ../tool/admin_seed.mjs
//
// Idempotent-ish: re-running updates docs and reuses existing auth users.

import {readFileSync, existsSync} from "node:fs";
import {homedir, tmpdir} from "node:os";
import {join} from "node:path";
import {initializeApp, cert, refreshToken} from "firebase-admin/app";
import {getFirestore, FieldValue, Timestamp} from "firebase-admin/firestore";
import {getAuth} from "firebase-admin/auth";

const PROJECT = "smart-campus-asst-8391";
const PASSWORD = "campus123";

// Prefer a service-account key (Firestore Admin requires it). Falls back to the
// developer's Firebase CLI login (authorized_user) for Auth-only operations.
function credential() {
  const saPath = process.env.GOOGLE_APPLICATION_CREDENTIALS ||
      join(tmpdir(), "sca_sa.json");
  if (existsSync(saPath)) return cert(JSON.parse(readFileSync(saPath, "utf8")));
  const cfg = JSON.parse(
    readFileSync(`${homedir()}/.config/configstore/firebase-tools.json`));
  const creds = {
    type: "authorized_user",
    client_id: "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com",
    client_secret: "j9iVZfS8kkCEFUPaAeJV0sAi",
    refresh_token: cfg.tokens.refresh_token,
  };
  const p = join(tmpdir(), "sca_authorized_user.json");
  readFileSync; // noop to keep import used
  return refreshToken(p);
}

initializeApp({credential: credential(), projectId: PROJECT});
const db = getFirestore();
const auth = getAuth();

const emailFor = (id) => `${id}@campus.local`;

async function run() {
  await seedCourses();
  await seedClasses();
  await seedAssignments();
  await seedEvents();
  await seedAnnouncements();
  await seedMap();
  await seedAdminStats();
  await seedUsers();
  await seedPending();
  await db.collection("_meta").doc("seed").set({appliedAt: FieldValue.serverTimestamp()});
  console.log("✓ Seed complete. Logins use password 'campus123'.");
}

async function seedCourses() {
  const courses = {
    MATH401: {code: "MATH-401", title: "Advanced Calculus", profName: "Dr. Emily Roberts",
      dept: "Department of Mathematics", initials: "ER", studentCount: 42,
      sessions: [
        {day: "MON", start: "11:30", end: "13:00", room: "Room 204"},
        {day: "WED", start: "11:30", end: "13:00", room: "Room 204"},
        {day: "FRI", start: "10:00", end: "11:30", room: "Lab 2"}],
      resources: [
        {name: "Syllabus.pdf", size: "240 KB"},
        {name: "Lecture Notes — Week 6.pdf", size: "1.8 MB"},
        {name: "Practice Midterm.pdf", size: "512 KB"}]},
    MATH220: {code: "MATH-220", title: "Linear Algebra", profName: "Dr. Chen",
      dept: "Department of Mathematics", initials: "LC", studentCount: 36,
      sessions: [
        {day: "TUE", start: "13:00", end: "14:30", room: "Room 112"},
        {day: "THU", start: "13:00", end: "14:30", room: "Room 112"}],
      resources: [{name: "Course Outline.pdf", size: "180 KB"}]},
    ART150: {code: "ART-150", title: "Art History", profName: "Dr. Vance",
      dept: "Department of Fine Arts", initials: "DV", studentCount: 58,
      sessions: [{day: "MON", start: "14:00", end: "15:30", room: "Room 202"}], resources: []},
    PHYS210: {code: "PHYS-210", title: "Physics Seminar", profName: "Dr. Okafor",
      dept: "Department of Physics", initials: "DO", studentCount: 24,
      sessions: [{day: "MON", start: "16:00", end: "17:30", room: "Lab 3"}], resources: []},
  };
  for (const [id, c] of Object.entries(courses)) {
    await db.collection("courses").doc(id).set(c);
  }
}

async function clearAndAdd(coll, items, build) {
  // wipe existing then add (keeps re-runs clean for collections without stable ids)
  const snap = await db.collection(coll).get();
  const batch = db.batch();
  snap.forEach((d) => batch.delete(d.ref));
  await batch.commit();
  for (const it of items) await db.collection(coll).add(build(it));
}

async function seedClasses() {
  const t = new Date();
  const today = Timestamp.fromDate(new Date(t.getFullYear(), t.getMonth(), t.getDate()));
  const items = [
    {courseId: "MATH220", code: "MATH-220", title: "Linear Algebra", profName: "Dr. Chen", start: "09:00", end: "10:30", room: "Room 112", status: "confirmed"},
    {courseId: "MATH401", code: "MATH-401", title: "Advanced Calculus", profName: "Dr. Emily Roberts", start: "11:30", end: "13:00", room: "Room 204", status: "confirmed"},
    {courseId: "ART150", code: "ART-150", title: "Art History", profName: "Dr. Vance", start: "14:00", end: "15:30", room: "Room 202", status: "roomchanged"},
    {courseId: "PHYS210", code: "PHYS-210", title: "Physics Seminar", profName: "Dr. Okafor", start: "16:00", end: "17:30", room: "Lab 3", status: "cancelled"},
  ];
  await clearAndAdd("classes", items, (c) => ({...c, date: today}));
}

async function seedAssignments() {
  const now = Date.now();
  const day = 86400000;
  const items = [
    {courseId: "PHYS210", code: "PHYS-210", title: "Physics Lab Report", type: "assignment", days: 1},
    {courseId: "ART150", code: "ART-150", title: "Essay: Modern Art", type: "assignment", days: 3},
    {courseId: "MATH401", code: "MATH-401", title: "Problem Set 4", type: "problemset", days: 5},
    {courseId: "MATH401", code: "MATH-401", title: "Midterm Exam", type: "exam", days: 9},
  ];
  await clearAndAdd("assignments", items, (a) => ({
    courseId: a.courseId, code: a.code, title: a.title, type: a.type,
    dueAt: Timestamp.fromDate(new Date(now + a.days * day)),
    description: "", createdByUid: "", createdAt: FieldValue.serverTimestamp(),
  }));
}

async function seedEvents() {
  const items = [
    {title: "Annual Tech Mixer", cat: "Career", date: "Today · 5:00 PM", loc: "Innovation Hub", featured: true, tint: 0xFF1F3A5F},
    {title: "Guest Lecture: Quantum Computing", cat: "Academic", date: "Oct 24 · 2:00 PM", loc: "Auditorium A", featured: false, tint: 0xFF3E5C76},
    {title: "Inter-College Basketball Finals", cat: "Sports", date: "Oct 25 · 6:30 PM", loc: "Main Arena", featured: false, tint: 0xFF5B4B7A},
    {title: "Wellness & Mindfulness Night", cat: "Social", date: "Oct 26 · 7:00 PM", loc: "Student Union", featured: false, tint: 0xFF6A4E8C},
    {title: "Career Fair: Spring Internships", cat: "Career", date: "Oct 27 · 10:00 AM", loc: "Grand Hall", featured: false, tint: 0xFF244A66},
  ];
  await clearAndAdd("events", items, (e) => e);
}

async function seedAnnouncements() {
  const base = Date.now();
  const items = [
    {dept: "Campus Safety", accent: 0xFFBA1A1A, title: "Emergency Power Outage — Science Wing", urgent: true, pinned: true, minsAgo: 20,
      body: "A planned electrical maintenance will cut power to the Science Wing from 1–4 PM today. Labs are closed during this window.",
      summary: "Science Wing power is out 1–4 PM today for maintenance. All labs closed; classes relocated — check your schedule."},
    {dept: "Engineering", accent: 0xFF3E8E9B, title: "Robotics Lab Hours Extended", urgent: false, pinned: false, minsAgo: 120,
      body: "", summary: "Robotics Lab now open until 11 PM on weekdays through finals. Badge access required after 8 PM."},
    {dept: "General", accent: 0xFF002147, title: "Fall Registration Opens Monday", urgent: false, pinned: false, minsAgo: 300,
      body: "", summary: "Spring course registration opens Monday 8 AM by seniority. Meet your advisor before booking."},
    {dept: "Athletics", accent: 0xFF9C5BB0, title: "Gym Closed for Tournament", urgent: false, pinned: false, minsAgo: 1500,
      body: "", summary: "Main gym reserved for the regional tournament Fri–Sun. Annex facilities remain open to all students."},
  ];
  await clearAndAdd("announcements", items, (a) => ({
    dept: a.dept, accent: a.accent, title: a.title, body: a.body, summary: a.summary,
    urgent: a.urgent, pinned: a.pinned, audience: "All Students", createdByUid: "",
    createdAt: Timestamp.fromDate(new Date(base - a.minsAgo * 60000)),
  }));
}

async function seedMap() {
  const pins = [
    {label: "Science Center", x: 58, y: 38, kind: "study"},
    {label: "Library", x: 30, y: 60, kind: "study"},
    {label: "Union Café", x: 72, y: 66, kind: "cafe"},
    {label: "Print Hub", x: 42, y: 28, kind: "printer"},
  ];
  await clearAndAdd("mapPins", pins, (p) => p);
}

async function seedAdminStats() {
  await db.collection("adminStats").doc("overview").set({
    stats: [
      {value: "12,402", label: "Total Users"},
      {value: "8,230", label: "Active Students", trend: "4% increase", trendUp: true},
      {value: "124", label: "Published Announcements"}],
    engagementWeek: [42, 58, 51, 67, 73, 61, 80],
    engagementMonth: [55, 62, 70, 78],
  });
}

async function activatedUser(o) {
  const email = emailFor(o.idNumber);
  let uid;
  try {
    uid = (await auth.createUser({email, password: PASSWORD})).uid;
  } catch (e) {
    if (e.code === "auth/email-already-exists") {
      uid = (await auth.getUserByEmail(email)).uid;
    } else throw e;
  }
  await auth.setCustomUserClaims(uid, {role: o.roles[0]});
  await db.collection("users").doc(o.docId).set({
    name: o.name, first: o.name.split(" ")[0], idNumber: o.idNumber, initials: o.initials,
    roles: o.roles, dept: o.dept ?? "", program: o.program ?? "",
    enrolledCourseIds: o.enrolled ?? [], teachingCourseIds: o.teaching ?? [],
    rsvps: [], status: "active", authUid: uid,
  });
  console.log(`  ✓ ${o.name} (${o.idNumber}) → role=${o.roles[0]}`);
}

async function seedUsers() {
  await activatedUser({docId: "student_alex", idNumber: "202400123", name: "Alex Morgan",
    initials: "AM", roles: ["student"], dept: "Computer Science", program: "Undergraduate",
    enrolled: ["MATH401", "MATH220", "ART150", "PHYS210"]});
  await activatedUser({docId: "staff_wilson", idNumber: "900100", name: "Prof. Wilson",
    initials: "PW", roles: ["staff"], dept: "Mathematics", program: "Faculty",
    teaching: ["MATH401", "MATH220"]});
  await activatedUser({docId: "admin_console", idNumber: "500001", name: "Admin Console",
    initials: "AD", roles: ["admin"], dept: "Administration", program: "Administrator"});
}

async function seedPending() {
  await db.collection("users").doc("student_jordan").set({
    name: "Jordan Lee", first: "Jordan", idNumber: "202400999", initials: "JL",
    roles: ["student"], dept: "Computer Science", program: "Undergraduate",
    enrolledCourseIds: ["MATH401", "ART150"], teachingCourseIds: [], rsvps: [],
    status: "unclaimed", authUid: null,
  });
  await db.collection("signupTokens").doc("DEMO-ACTIVATE-001").set({
    targetUserDocId: "student_jordan", idNumber: "202400999", used: false,
    createdByUid: "seed", createdAt: FieldValue.serverTimestamp(),
    expiresAt: Timestamp.fromDate(new Date(Date.now() + 30 * 86400000)),
  });
}

run().then(() => process.exit(0)).catch((e) => {
  console.error("Seed failed:", e);
  process.exit(1);
});
