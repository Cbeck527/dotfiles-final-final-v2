export interface Options {
  host: string;
  ref: string;
  build: boolean;
}

export function parseOptions(params: URLSearchParams): Options {
  for (const key of params.keys()) {
    if (!["host", "ref", "build"].includes(key)) {
      throw new Error("Supported parameters: host, ref, build.");
    }
    if (params.getAll(key).length !== 1) {
      throw new Error("Each parameter may appear only once.");
    }
  }

  const host = params.get("host") ?? "auto";
  if (!["auto", "beckbook-pro", "mac-h99xrph3j9", "sweetums", "coder"].includes(host)) {
    throw new Error("host must be auto, beckbook-pro, mac-h99xrph3j9, sweetums, or coder.");
  }

  const ref = params.get("ref") ?? "trunk";
  if (
    ref.length > 128 ||
    !/^[A-Za-z0-9][A-Za-z0-9._/-]*$/.test(ref) ||
    ref.includes("..") ||
    ref.split("/").some((part) => !part || part.startsWith(".") || part.endsWith(".") || part.endsWith(".lock"))
  ) {
    throw new Error("ref must be a branch or tag using letters, digits, dots, underscores, slashes, or hyphens.");
  }

  const build = params.get("build") ?? "1";
  if (build !== "0" && build !== "1") {
    throw new Error("build must be 0 or 1.");
  }

  return { host, ref, build: build === "1" };
}
