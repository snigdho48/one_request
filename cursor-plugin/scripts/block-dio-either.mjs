#!/usr/bin/env node
/**
 * Deny `flutter pub add dio|dart_either|either_dart|flutter_easyloading` when the
 * project already depends on one_request (those packages are re-exported).
 * Fail open on parse/IO errors.
 */

import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { stdin } from "node:process";

const ALLOW = { permission: "allow" };
const BLOCKED = /\b(dio|dart_either|either_dart|flutter_easyloading|web_socket_channel|connectivity_plus)\b/;

function reply(payload) {
  process.stdout.write(`${JSON.stringify(payload)}\n`);
}

async function readStdinJson() {
  const chunks = [];
  for await (const chunk of stdin) chunks.push(chunk);
  const raw = Buffer.concat(chunks).toString("utf8").trim();
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

function commandOf(input) {
  if (!input || typeof input !== "object") return "";
  return String(
    input.command ||
      input.tool_input?.command ||
      input.command_line ||
      ""
  );
}

function cwdOf(input) {
  return String(
    input?.cwd ||
      input?.workspace_roots?.[0] ||
      process.cwd()
  );
}

function inspectPubspec(startDir) {
  let dir = startDir;
  for (let i = 0; i < 8; i += 1) {
    const file = join(dir, "pubspec.yaml");
    if (existsSync(file)) {
      const text = readFileSync(file, "utf8");
      const name = (text.match(/^name:\s*([^\s#]+)/m) || [])[1] || "";
      return {
        isOneRequestPackage: name === "one_request",
        dependsOnOneRequest: /^\s*one_request\s*:/m.test(text),
      };
    }
    const parent = join(dir, "..");
    if (parent === dir) break;
    dir = parent;
  }
  return { isOneRequestPackage: false, dependsOnOneRequest: false };
}

async function main() {
  try {
    const input = await readStdinJson();
    const command = commandOf(input || {});
    if (!/\bpub\s+add\b/i.test(command)) {
      reply(ALLOW);
      return;
    }
    if (!BLOCKED.test(command)) {
      reply(ALLOW);
      return;
    }
    const spec = inspectPubspec(cwdOf(input || {}));
    if (spec.isOneRequestPackage) {
      reply(ALLOW);
      return;
    }
    if (!spec.dependsOnOneRequest && !/\bone_request\b/.test(command)) {
      reply(ALLOW);
      return;
    }
    reply({
      permission: "deny",
      agent_message:
        "Do not add dio, dart_either, either_dart, flutter_easyloading, web_socket_channel, or connectivity_plus. one_request already depends on them. Run `flutter pub add one_request` only, then `import 'package:one_request/one_request.dart';`.",
      user_message:
        "Blocked extra packages. one_request already includes dio, dart_either, web_socket_channel, and connectivity_plus.",
    });
  } catch {
    reply(ALLOW);
  }
}

main();
