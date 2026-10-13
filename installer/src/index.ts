import { parseOptions } from "./options";
import { renderScript, shellQuote } from "./render";

export default {
  fetch(request: Request): Response {
    const url = new URL(request.url);
    const headers = {
      "Content-Type": "text/plain; charset=utf-8",
      "Cache-Control": "no-store",
      "X-Content-Type-Options": "nosniff",
    };
    const reply = (body: string, status = 200, extraHeaders = {}) =>
      new Response(request.method === "HEAD" ? null : body, {
        status,
        headers: { ...headers, ...extraHeaders },
      });
    const error = (message: string, status: number, extraHeaders = {}) =>
      reply(`#!/bin/sh\nprintf '%s\\n' ${shellQuote(message)} >&2\nexit 1\n`, status, extraHeaders);

    if (request.method !== "GET" && request.method !== "HEAD") {
      return error("Use GET or HEAD.", 405, { Allow: "GET, HEAD" });
    }
    if (url.pathname !== "/") {
      return error("Installer is served at /.", 404);
    }

    let options;
    try {
      options = parseOptions(url.searchParams);
    } catch (cause) {
      return error(cause instanceof Error ? cause.message : "Invalid options.", 400);
    }
    return reply(renderScript(options));
  },
} satisfies ExportedHandler<Env>;
