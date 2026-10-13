import bootstrap from "./bootstrap.sh";
import type { Options } from "./options";

export function renderScript(options: Options): string {
  const settings = [
    `host=${shellQuote(options.host)}`,
    `ref=${shellQuote(options.ref)}`,
    `build=${options.build ? "1" : "0"}`,
  ].join("\n");

  // The quoted heredoc lets callers use sh while the installer runs in Bash.
  return `#!/bin/sh
command -v bash >/dev/null 2>&1 || { printf '%s\\n' 'Bash is required.' >&2; exit 1; }
bash <<'NIX_CONFIG_INSTALLER'
${bootstrap.replace("# __INSTALLER_OPTIONS__", () => settings)}
NIX_CONFIG_INSTALLER
`;
}

export function shellQuote(value: string): string {
  return "'" + value.replaceAll("'", "'\\''") + "'";
}
