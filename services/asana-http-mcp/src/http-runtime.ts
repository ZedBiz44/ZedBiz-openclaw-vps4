import { randomUUID, timingSafeEqual } from "node:crypto";
import type { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { createMcpExpressApp } from "@modelcontextprotocol/sdk/server/express.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { isInitializeRequest } from "@modelcontextprotocol/sdk/types.js";
import type { NextFunction, Request, Response } from "express";

type SessionEntry = {
  server: Server;
  transport: StreamableHTTPServerTransport;
  lastSeen: number;
};

type HttpMcpOptions = {
  serviceName: string;
  createServer: () => Server;
};

function readPositiveInteger(name: string, fallback: number): number {
  const value = Number.parseInt(process.env[name] ?? "", 10);
  return Number.isFinite(value) && value > 0 ? value : fallback;
}

function tokenMatches(actual: string | undefined, expected: string): boolean {
  if (!actual?.startsWith("Bearer ")) return false;
  const supplied = Buffer.from(actual.slice(7));
  const wanted = Buffer.from(expected);
  return supplied.length === wanted.length && timingSafeEqual(supplied, wanted);
}

export async function startHttpMcpService(options: HttpMcpOptions): Promise<void> {
  const port = readPositiveInteger("PORT", 8080);
  const bindHost = process.env.MCP_BIND_HOST ?? "127.0.0.1";
  const sessionTtlMs = readPositiveInteger("MCP_SESSION_TTL_MS", 15 * 60 * 1000);
  const maxSessions = readPositiveInteger("MCP_MAX_SESSIONS", 64);
  const authToken = process.env.MCP_AUTH_TOKEN;
  if (!authToken) throw new Error("MCP_AUTH_TOKEN is required");

  const allowedHosts = (process.env.MCP_ALLOWED_HOSTS ?? "localhost,127.0.0.1")
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean);
  const app = createMcpExpressApp({ host: bindHost, allowedHosts });
  const sessions = new Map<string, SessionEntry>();

  const closeSession = async (sessionId: string): Promise<void> => {
    const entry = sessions.get(sessionId);
    if (!entry) return;
    sessions.delete(sessionId);
    try {
      await entry.transport.close();
    } catch (error) {
      console.error(`[${options.serviceName}] transport close failed for ${sessionId}:`, error);
    }
    try {
      await entry.server.close();
    } catch (error) {
      console.error(`[${options.serviceName}] server close failed for ${sessionId}:`, error);
    }
  };

  const requireAuth = (req: Request, res: Response, next: NextFunction): void => {
    if (!tokenMatches(req.header("authorization"), authToken)) {
      res.status(401).json({ error: "unauthorized" });
      return;
    }
    next();
  };

  app.get("/healthz", (_req, res) => {
    res.json({
      ok: true,
      service: options.serviceName,
      sessions: sessions.size,
      maxSessions,
      sessionTtlMs,
    });
  });

  app.post("/mcp", requireAuth, async (req, res) => {
    const sessionId = req.header("mcp-session-id");
    try {
      if (sessionId && sessions.has(sessionId)) {
        const entry = sessions.get(sessionId)!;
        entry.lastSeen = Date.now();
        await entry.transport.handleRequest(req, res, req.body);
        return;
      }

      if (sessionId || !isInitializeRequest(req.body)) {
        res.status(400).json({
          jsonrpc: "2.0",
          error: { code: -32000, message: "Invalid or missing MCP session" },
          id: null,
        });
        return;
      }

      if (sessions.size >= maxSessions) {
        const oldest = [...sessions.entries()].sort(
          ([, left], [, right]) => left.lastSeen - right.lastSeen,
        )[0]?.[0];
        if (oldest) await closeSession(oldest);
      }

      const server = options.createServer();
      let transport!: StreamableHTTPServerTransport;
      transport = new StreamableHTTPServerTransport({
        sessionIdGenerator: randomUUID,
        onsessioninitialized: (newSessionId) => {
          sessions.set(newSessionId, {
            server,
            transport,
            lastSeen: Date.now(),
          });
        },
      });
      transport.onclose = () => {
        const closedSessionId = transport.sessionId;
        if (closedSessionId) sessions.delete(closedSessionId);
      };
      await server.connect(transport);
      await transport.handleRequest(req, res, req.body);
    } catch (error) {
      console.error(`[${options.serviceName}] POST /mcp failed:`, error);
      if (!res.headersSent) {
        res.status(500).json({
          jsonrpc: "2.0",
          error: { code: -32603, message: "Internal MCP server error" },
          id: null,
        });
      }
    }
  });

  app.get("/mcp", requireAuth, async (req, res) => {
    const sessionId = req.header("mcp-session-id");
    const entry = sessionId ? sessions.get(sessionId) : undefined;
    if (!sessionId || !entry) {
      res.status(400).send("Invalid or missing MCP session");
      return;
    }
    entry.lastSeen = Date.now();
    await entry.transport.handleRequest(req, res);
  });

  app.delete("/mcp", requireAuth, async (req, res) => {
    const sessionId = req.header("mcp-session-id");
    const entry = sessionId ? sessions.get(sessionId) : undefined;
    if (!sessionId || !entry) {
      res.status(400).send("Invalid or missing MCP session");
      return;
    }
    entry.lastSeen = Date.now();
    await entry.transport.handleRequest(req, res);
  });

  const sweep = setInterval(() => {
    const cutoff = Date.now() - sessionTtlMs;
    for (const [sessionId, entry] of sessions) {
      if (entry.lastSeen < cutoff) void closeSession(sessionId);
    }
  }, Math.min(60_000, Math.max(5_000, Math.floor(sessionTtlMs / 3))));
  sweep.unref();

  const httpServer = app.listen(port, bindHost, () => {
    console.log(`[${options.serviceName}] listening on ${bindHost}:${port}`);
  });

  const shutdown = async (signal: string): Promise<void> => {
    console.log(`[${options.serviceName}] received ${signal}; shutting down`);
    clearInterval(sweep);
    httpServer.close();
    await Promise.all([...sessions.keys()].map(closeSession));
    process.exit(0);
  };

  process.once("SIGTERM", () => void shutdown("SIGTERM"));
  process.once("SIGINT", () => void shutdown("SIGINT"));
}
