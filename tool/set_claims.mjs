// Moved to functions/scripts/set_claims.mjs — run:
//   cd functions && npm run set-claims
import {spawnSync} from "node:child_process";
import {fileURLToPath} from "node:url";
import {dirname, join} from "node:path";

const functionsDir = join(dirname(fileURLToPath(import.meta.url)), "../functions");
const r = spawnSync("npm", ["run", "set-claims"], {cwd: functionsDir, stdio: "inherit", shell: true});
process.exit(r.status ?? 1);
