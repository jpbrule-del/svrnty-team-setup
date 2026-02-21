#!/usr/bin/env node
/**
 * sync-manifest.js — Sync plugin.json and README.md from skill/command frontmatter
 *
 * Zero dependencies — uses only Node.js built-in fs/path modules.
 *
 * Reads YAML frontmatter from:
 *   - skills/*/SKILL.md
 *   - commands/*.md
 *
 * Updates:
 *   - .claude-plugin/plugin.json skills[] and commands[] arrays
 *   - README.md tables between HTML comment markers
 */

const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "../..");
const MANIFEST_PATH = path.join(ROOT, ".claude-plugin/plugin.json");
const README_PATH = path.join(ROOT, "README.md");

// --- Simple YAML frontmatter parser (no deps) ---

function parseFrontmatter(content) {
  const match = content.match(/^---\n([\s\S]*?)\n---/);
  if (!match) return null;

  const result = {};
  for (const line of match[1].split("\n")) {
    const colonIdx = line.indexOf(":");
    if (colonIdx === -1) continue;
    const key = line.slice(0, colonIdx).trim();
    let value = line.slice(colonIdx + 1).trim();
    // Strip surrounding quotes
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    result[key] = value;
  }
  return result;
}

// --- Discover skills ---

function discoverSkills() {
  const skillsDir = path.join(ROOT, "skills");
  if (!fs.existsSync(skillsDir)) return [];

  const skills = [];
  for (const entry of fs.readdirSync(skillsDir, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    const skillMd = path.join(skillsDir, entry.name, "SKILL.md");
    if (!fs.existsSync(skillMd)) continue;

    const content = fs.readFileSync(skillMd, "utf8");
    const fm = parseFrontmatter(content);
    if (!fm) continue;

    skills.push({
      path: `./skills/${entry.name}`,
      description: fm.description || "",
      triggers: [], // Could parse from description if needed
    });
  }
  return skills;
}

// --- Discover commands ---

function discoverCommands() {
  const cmdsDir = path.join(ROOT, "commands");
  if (!fs.existsSync(cmdsDir)) return [];

  const commands = [];
  for (const file of fs.readdirSync(cmdsDir)) {
    if (!file.endsWith(".md")) continue;
    const filePath = path.join(cmdsDir, file);
    const content = fs.readFileSync(filePath, "utf8");
    const fm = parseFrontmatter(content);
    if (!fm) continue;

    commands.push({
      path: `./commands/${file}`,
      description: fm.description || "",
    });
  }
  return commands;
}

// --- Update manifest ---

function updateManifest(skills, commands) {
  const manifest = JSON.parse(fs.readFileSync(MANIFEST_PATH, "utf8"));

  manifest.skills = skills;
  manifest.commands = commands;

  fs.writeFileSync(MANIFEST_PATH, JSON.stringify(manifest, null, 2) + "\n");
  console.log(
    `Updated manifest: ${skills.length} skills, ${commands.length} commands`
  );
}

// --- Update README between markers ---

function updateReadmeSection(readme, beginMarker, endMarker, newContent) {
  const beginIdx = readme.indexOf(beginMarker);
  const endIdx = readme.indexOf(endMarker);
  if (beginIdx === -1 || endIdx === -1) return readme;

  return (
    readme.slice(0, beginIdx + beginMarker.length) +
    "\n" +
    newContent +
    readme.slice(endIdx)
  );
}

// --- Main ---

const skills = discoverSkills();
const commands = discoverCommands();

updateManifest(skills, commands);

// Update README hooks reference if markers exist
if (fs.existsSync(README_PATH)) {
  let readme = fs.readFileSync(README_PATH, "utf8");

  // Discover hooks from hooks.json for README sync
  const hooksJsonPath = path.join(ROOT, "hooks/hooks.json");
  if (fs.existsSync(hooksJsonPath)) {
    const hooksConfig = JSON.parse(fs.readFileSync(hooksJsonPath, "utf8"));
    const hookEntries = [];

    for (const [event, matchers] of Object.entries(hooksConfig.hooks || {})) {
      for (const matcher of matchers) {
        const matcherStr = matcher.matcher || "—";
        for (const hook of matcher.hooks || []) {
          const scriptMatch = (hook.command || "").match(
            /([a-zA-Z0-9_-]+\.sh)/
          );
          if (scriptMatch) {
            hookEntries.push({
              script: scriptMatch[1],
              event,
              matcher: matcherStr,
            });
          }
        }
      }
    }

    if (hookEntries.length > 0) {
      let table =
        "## Hooks Reference\n\n| Hook | Event | Matcher | Purpose |\n|------|-------|---------|---------|";
      for (const h of hookEntries) {
        table += `\n| \`${h.script}\` | ${h.event} | ${h.matcher === "—" ? "—" : "`" + h.matcher + "`"} | — |`;
      }
      table += "\n";

      readme = updateReadmeSection(
        readme,
        "<!-- BEGIN HOOKS REFERENCE -->",
        "<!-- END HOOKS REFERENCE -->",
        table
      );
    }
  }

  fs.writeFileSync(README_PATH, readme);
  console.log("Updated README.md");
}

console.log("Sync complete.");
