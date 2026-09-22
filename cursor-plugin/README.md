# one_request Cursor plugin

Teaches Cursor to use **one_request** as the only Flutter HTTP client.

## Why this exists

When an agent sees `CancelToken` / `Interceptor` / `Either`, it often runs `flutter pub add dio` and `flutter pub add dart_either` (or the old `either_dart`). Those packages are already inside `one_request` and are **re-exported**. This plugin:

- Always-on rule: never add those packages; import only `package:one_request/one_request.dart`
- Skill + `/one-request-setup` command for configure / JWT / wrap
- Shell hook that **denies** `pub add dio|dart_either|either_dart|flutter_easyloading|web_socket_channel|connectivity_plus` when `one_request` is present

## Install (local, immediate)

Copy or junction this folder to:

```
%USERPROFILE%\.cursor\plugins\local\one-request
```

Then reload the Cursor window. Confirm in **Customize** that `one-request` is listed.

## Formats

This is a **Cursor Plugin** (`.cursor-plugin/plugin.json`) so rules, commands, and hooks load. Cursor also supports the Agent Plugins standard (`plugin.json` at plugin root, skills + MCP only). Rules/hooks require the Cursor format.
