// Grants the `role` custom claim to seeded accounts (staff/admin writes in rules).
//
// Prereq: service-account key at tool/service-account.json (or functions/sa-key.json)
//   Firebase Console → Project settings → Service accounts → Generate new private key
//
// Run from repo root:
//   cd functions && npm run set-claims

import {existsSync, readFileSync} from "node:fs";
import {fileURLToPath} from "node:url";
import {dirname, join} from "node:path";
import {initializeApp, cert} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";

const here = dirname(fileURLToPath(import.meta.url));
const candidates = [
  join(here, "../../tool/service-account.json"),
  join(here, "../sa-key.json"),
];
const keyPath = candidates.find(existsSync);
if (!keyPath) {
  console.error(
    "Missing service account key. Save it as tool/service-account.json\n" +
      "(Firebase Console → Project settings → Service accounts → Generate new private key)",
  );
  process.exit(1);
}

const key = JSON.parse(readFileSync(keyPath, "utf8"));
initializeApp({credential: cert(key)});

const emailFor = (id) => `${id}@campus.local`;
const accounts = [
  {id: "900100", role: "staff"},
  {id: "500001", role: "admin"},
  {id: "202400123", role: "student"},
];

for (const a of accounts) {
  try {
    const user = await getAuth().getUserByEmail(emailFor(a.id));
    await getAuth().setCustomUserClaims(user.uid, {role: a.role});
    console.log(`✓ ${a.id} → role=${a.role}`);
  } catch (e) {
    console.error(`✗ ${a.id}: ${e.message}`);
  }
}
console.log("Done. Users must sign out/in to refresh their token.");
