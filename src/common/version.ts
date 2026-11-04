import * as fs from 'fs';
import * as path from 'path';

export interface VersionInfo {
  name: string;
  version: string;
  releaseDir: string;
  commit: string;
  builtAt: string;
}

let cached: VersionInfo | null = null;

/**
 * Reads version details at runtime, so the running process always reports
 * the release it was actually started from (not whatever the symlink points to now).
 *  - package.json  -> version
 *  - RELEASE_INFO.json (written by CI) -> git commit + build time
 *  - realpath of this file -> /opt/nest-app/releases/<version>
 */
export function getVersionInfo(): VersionInfo {
  if (cached) return cached;

  const appRoot = path.resolve(__dirname, '..', '..');
  const pkg = JSON.parse(fs.readFileSync(path.join(appRoot, 'package.json'), 'utf8'));

  let commit = 'local';
  let builtAt = 'local';
  const releaseInfoPath = path.join(appRoot, 'RELEASE_INFO.json');
  if (fs.existsSync(releaseInfoPath)) {
    const ri = JSON.parse(fs.readFileSync(releaseInfoPath, 'utf8'));
    commit = ri.commit ?? commit;
    builtAt = ri.builtAt ?? builtAt;
  }

  cached = {
    name: pkg.name,
    version: pkg.version,
    releaseDir: fs.realpathSync(appRoot),
    commit,
    builtAt,
  };
  return cached;
}
