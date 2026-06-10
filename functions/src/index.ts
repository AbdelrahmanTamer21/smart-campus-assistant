import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {getFirestore, FieldValue, QueryDocumentSnapshot} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onDocumentUpdated, onDocumentCreated} from "firebase-functions/v2/firestore";

initializeApp();
const db = getFirestore();

const emailFor = (id: string) => `${id}@campus.local`;

// ── F0: redeem a one-time QR activation token (atomic, server-trusted) ──
export const redeemSignupToken = onCall(async (req) => {
  const token = (req.data?.token ?? "").toString().trim();
  const password = (req.data?.password ?? "").toString();
  if (!token || password.length < 8) {
    throw new HttpsError("invalid-argument", "Token and an 8+ char password are required.");
  }

  const tokenRef = db.collection("signupTokens").doc(token);
  const record = await db.runTransaction(async (tx) => {
    const snap = await tx.get(tokenRef);
    if (!snap.exists) throw new HttpsError("not-found", "Invalid activation code.");
    const t = snap.data()!;
    if (t.used === true) throw new HttpsError("failed-precondition", "Code already used.");
    const expires = t.expiresAt?.toDate?.();
    if (expires && expires < new Date()) {
      throw new HttpsError("failed-precondition", "Code expired.");
    }
    const recRef = db.collection("users").doc(t.targetUserDocId);
    const rec = await tx.get(recRef);
    if (!rec.exists || rec.data()?.status !== "unclaimed") {
      throw new HttpsError("failed-precondition", "Account already activated.");
    }
    tx.update(tokenRef, {used: true, usedAt: FieldValue.serverTimestamp()});
    return {idNumber: t.idNumber as string, recRef, roles: rec.data()?.roles ?? ["student"]};
  });

  // Create the auth user, bind it to the record, set the role claim.
  const user = await getAuth().createUser({email: emailFor(record.idNumber), password});
  const role = (record.roles[0] ?? "student") as string;
  await getAuth().setCustomUserClaims(user.uid, {role});
  await record.recRef.update({authUid: user.uid, status: "active"});

  return {idNumber: record.idNumber};
});

// ── F10: notify enrolled students when a class occurrence changes ──
export const onClassChanged = onDocumentUpdated("classes/{id}", async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;
  const changed =
    before.room !== after.room ||
    before.status !== after.status ||
    before.start !== after.start;
  if (!changed) return;

  const msg =
    after.status === "cancelled" ? `${after.title} has been cancelled.` :
    after.status === "roomchanged" || before.room !== after.room ?
      `${after.title} moved to ${after.room}.` :
      `${after.title} was updated.`;

  await fanOut(`course_${after.courseId}`, after.courseId, {
    title: "Schedule update", body: msg, type: "class", route: "/schedule",
  });
});

// ── F10: notify when a deadline/assignment is created or changed ──
export const onAssignmentWritten = onDocumentCreated("assignments/{id}", async (event) => {
  const a = event.data?.data();
  if (!a) return;
  await fanOut(`course_${a.courseId}`, a.courseId, {
    title: "New deadline", body: `${a.title} (${a.code})`, type: "deadline",
    route: `/course/${a.courseId}`,
  });
});

// ── F10: fan out announcements to the target audience ──
export const onAnnouncementCreated = onDocumentCreated("announcements/{id}", async (event) => {
  const a = event.data?.data();
  if (!a) return;
  const title = a.urgent ? `⚠️ ${a.title}` : a.title;
  const body = a.summary || a.body || "";
  const payload = {title, body};

  if (a.audience === "Courses" && Array.isArray(a.targetCourseIds) && a.targetCourseIds.length > 0) {
    for (const courseId of a.targetCourseIds as string[]) {
      await fanOut(`course_${courseId}`, courseId, {
        title, body, type: "announcement", route: "/announcements",
      });
    }
    return;
  }

  if (a.audience === "Faculty" && Array.isArray(a.targetFacultyIds) && a.targetFacultyIds.length > 0) {
    await sendToTopic("faculty", {...payload, route: "/announcements"});
    await writeInAppNotifications(
      a.targetFacultyIds as string[],
      {title, body, type: "announcement", route: "/announcements"},
    );
    return;
  }

  const topic = audienceTopic(a.audience);
  await sendToTopic(topic, {...payload, route: "/announcements"});

  if (topic === "all_students") {
    const students = await db.collection("users")
      .where("roles", "array-contains", "student")
      .where("status", "==", "active").get();
    await writeInAppBatch(students.docs, {title, body, type: "announcement", route: "/announcements"});
  } else if (topic === "campus_wide") {
    const users = await db.collection("users").where("status", "==", "active").get();
    await writeInAppBatch(users.docs, {title, body, type: "announcement", route: "/announcements"});
  }
});

function audienceTopic(audience: string): string {
  switch (audience) {
    case "Faculty": return "faculty";
    case "Campus-Wide": return "campus_wide";
    default: return "all_students";
  }
}

async function writeInAppBatch(
  docs: QueryDocumentSnapshot[],
  n: {title: string; body: string; type: string; route: string},
) {
  const batch = db.batch();
  docs.forEach((doc) => {
    const ref = doc.ref.collection("notifications").doc();
    batch.set(ref, {
      title: n.title, body: n.body, type: n.type, route: n.route,
      read: false, createdAt: FieldValue.serverTimestamp(),
    });
  });
  await batch.commit();
}

async function writeInAppNotifications(
  userDocIds: string[],
  n: {title: string; body: string; type: string; route: string},
) {
  const batch = db.batch();
  for (const id of userDocIds) {
    const ref = db.collection("users").doc(id).collection("notifications").doc();
    batch.set(ref, {
      title: n.title, body: n.body, type: n.type, route: n.route,
      read: false, createdAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
}

async function sendToTopic(
  topic: string,
  n: {title: string; body: string; route?: string},
) {
  try {
    await getMessaging().send({
      topic,
      notification: {title: n.title, body: n.body},
      data: {
        title: n.title,
        body: n.body,
        ...(n.route ? {route: n.route} : {}),
      },
      android: {priority: "high"},
      apns: {payload: {aps: {sound: "default"}}},
    });
  } catch (e) {
    console.error("FCM send failed", topic, e);
  }
}

/** Push to a course topic + write in-app notifications for enrolled students. */
async function fanOut(
  topic: string,
  courseId: string,
  n: {title: string; body: string; type: string; route: string},
) {
  await sendToTopic(topic, {title: n.title, body: n.body, route: n.route});
  const enrolled = await db.collection("users")
    .where("enrolledCourseIds", "array-contains", courseId).get();
  const batch = db.batch();
  enrolled.forEach((doc) => {
    const ref = doc.ref.collection("notifications").doc();
    batch.set(ref, {
      title: n.title, body: n.body, type: n.type, route: n.route,
      read: false, createdAt: FieldValue.serverTimestamp(),
    });
  });
  await batch.commit();
}

// ── F6 (optional): server-side LLM. Stubbed; the client scripted engine is the
// default so the app runs with no extra keys. Wire a model here when desired. ──
export const askCampusAi = onCall(async (req) => {
  const message = (req.data?.message ?? "").toString();
  // Guardrail: the system prompt + context live here, never on the client.
  // Replace this stub with a Vertex AI / LLM call that receives the
  // server-built context and a strict campus-only system prompt.
  return {
    text: "The campus AI is currently running in on-device mode. " +
      `You asked: "${message.slice(0, 80)}".`,
  };
});
