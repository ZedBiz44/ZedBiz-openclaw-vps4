type QueryValue = string | number | boolean | null | undefined | string[];

export type AsanaRequestOptions = {
  query?: Record<string, QueryValue>;
  data?: unknown;
};

export class AsanaRestClient {
  private readonly token: string;
  private readonly baseUrl = "https://app.asana.com/api/1.0";

  constructor(token: string) {
    this.token = token;
  }

  private buildUrl(path: string, query: Record<string, QueryValue> = {}): URL {
    if (!path.startsWith("/") || path.startsWith("//")) {
      throw new Error("Asana API path must start with one slash");
    }
    const url = new URL(`${this.baseUrl}${path}`);
    for (const [key, value] of Object.entries(query)) {
      if (value === undefined || value === null) continue;
      if (Array.isArray(value)) {
        for (const item of value) url.searchParams.append(key, item);
      } else {
        url.searchParams.set(key, String(value));
      }
    }
    return url;
  }

  async request(
    method: string,
    path: string,
    options: AsanaRequestOptions = {},
  ): Promise<any> {
    const normalizedMethod = method.toUpperCase();
    if (!["GET", "POST", "PUT", "DELETE"].includes(normalizedMethod)) {
      throw new Error(`Unsupported Asana method: ${method}`);
    }

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 30_000);
    try {
      const response = await fetch(this.buildUrl(path, options.query), {
        method: normalizedMethod,
        headers: {
          Authorization: `Bearer ${this.token}`,
          Accept: "application/json",
          ...(options.data === undefined
            ? {}
            : { "Content-Type": "application/json" }),
        },
        body:
          options.data === undefined
            ? undefined
            : JSON.stringify({ data: options.data }),
        signal: controller.signal,
      });
      const raw = await response.text();
      let parsed: any = {};
      if (raw) {
        try {
          parsed = JSON.parse(raw);
        } catch {
          throw new Error(`Asana returned invalid JSON (${response.status})`);
        }
      }
      if (!response.ok) {
        const message =
          parsed.errors?.map((entry: any) => entry.message).join("; ") ||
          `Asana HTTP ${response.status}`;
        throw new Error(message);
      }
      return parsed.data ?? parsed;
    } finally {
      clearTimeout(timeout);
    }
  }

  async uploadAttachment(args: {
    parent: string;
    name?: string;
    url?: string;
    base64_data?: string;
    content_type?: string;
  }): Promise<any> {
    if (!args.url && !args.base64_data) {
      throw new Error("Provide either url or base64_data");
    }
    if (args.url && args.base64_data) {
      throw new Error("Provide url or base64_data, not both");
    }

    const form = new FormData();
    form.set("parent", args.parent);
    if (args.url) {
      form.set("url", args.url);
      form.set("name", args.name ?? args.url);
    } else {
      if (!args.name) throw new Error("name is required with base64_data");
      const bytes = Buffer.from(args.base64_data!, "base64");
      if (bytes.byteLength > 100 * 1024 * 1024) {
        throw new Error("Attachment exceeds Asana's 100 MB limit");
      }
      form.set(
        "file",
        new Blob([bytes], {
          type: args.content_type ?? "application/octet-stream",
        }),
        args.name,
      );
    }

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 120_000);
    try {
      const response = await fetch(`${this.baseUrl}/attachments`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${this.token}`,
          Accept: "application/json",
        },
        body: form,
        signal: controller.signal,
      });
      const parsed = await response.json();
      if (!response.ok) {
        throw new Error(
          parsed.errors?.map((entry: any) => entry.message).join("; ") ||
            `Asana HTTP ${response.status}`,
        );
      }
      return parsed.data;
    } finally {
      clearTimeout(timeout);
    }
  }
}
