# lean-intellij

A one-command setup that makes IntelliJ IDEA Ultimate leaner and faster for **Kotlin / Java / Gradle** development — without switching to a different IDE.

## Why

AI coding agents have changed what an IDE actually needs to do.

Features like Spring bean graphs, database UML diagrams, Maven support, code coverage overlays, and cloud settings sync made sense when the IDE was your primary interface for understanding and navigating a codebase. Today, tools like Claude Code and GitHub Copilot handle that layer — they read the code, reason about structure, suggest refactors, and write the boilerplate.

What the IDE still needs to do well: **syntax highlighting, go-to-definition, debugger, Gradle import, Git, and a terminal**. Everything else is overhead.

This project strips IntelliJ back to that core. The result is an IDE that starts faster, uses ~800 MB instead of 1.5–2 GB, and spends its CPU on the files you're actually editing — not on indexing Spring beans you're not looking at or running ML ranking on completions your AI agent is already handling.

---

Works by writing three files into your existing IDEA config directory:

| File | What it does |
|------|-------------|
| `idea.vmoptions` | Cuts default JVM heap from 2 GB → 1 GB; tunes GC and code cache |
| `disabled_plugins.txt` | Stops 92 built-in plugins from loading (Spring, Docker, Angular, Maven, localization packs, etc.) |
| `options/ide.general.xml` | Tunes registry: zero-latency editor rendering, telemetry off, 10 MB IntelliSense cap |

Nothing is uninstalled. Plugins stay on disk; they just don't load. One command undoes everything.

---

## Quick start

```bash
git clone https://github.com/your-username/lean-intellij
cd lean-intellij
chmod +x apply.sh
./apply.sh          # macOS / Linux
# — or —
.\apply.ps1         # Windows (PowerShell)
```

Restart IntelliJ IDEA. That's it.

---

## What this keeps (plugins that still load)

| Plugin | Why |
|--------|-----|
| `com.intellij.java` + `com.intellij.java.ide` | Java language support, inspections, refactoring |
| `org.jetbrains.kotlin` | Kotlin language support (K2 mode) |
| `org.jetbrains.plugins.gradle` + `com.intellij.gradle` + `org.jetbrains.idea.gradle.dsl` | Gradle project import and `.kts` support |
| `org.jetbrains.java.decompiler` | Navigate into library source (Cmd+Click on a dep) |
| `Git4Idea` + `intellij.git.commit.modal` | Git integration and commit UI |
| `org.jetbrains.plugins.terminal` | Integrated terminal |
| `JUnit` | Run individual test methods from the IDE gutter |
| `org.intellij.groovy` | Parse `.gradle` (Groovy DSL) build files |
| `org.toml.lang` | Gradle version catalogs (`libs.versions.toml`) |
| `com.intellij.mcpServer` | MCP server for Claude Code / AI agent tools |
| `intellij.platform.ijent.impl` | WSL and SSH remote development |

Everything else — 92 plugins — is disabled.

---

## What gets disabled (92 plugins)

| Category | Plugin IDs |
|----------|-----------|
| Web front-end | `AngularJS`, `JavaScript`, `HtmlTools`, `com.intellij.css`, `com.intellij.react`, `intellij.prettierJS`, `tslint`, `intellij.vitejs`, `intellij.webpack`, `intellij.webp`, `com.intellij.plugins.webcomponents`, `JSIntentionPowerPack` |
| Spring / Jakarta EE | `com.intellij.spring`, `com.intellij.spring.boot`, `com.intellij.spring.boot.initializr`, `com.intellij.thymeleaf`, `com.intellij.javaee`, `com.intellij.javaee.el`, `com.intellij.jpa.jpb.model` |
| Database / persistence | `com.intellij.database`, `com.intellij.flyway`, `com.intellij.liquibase` |
| Microservices | `com.intellij.microservices.jvm`, `com.intellij.microservices.ui`, `com.intellij.swagger`, `com.jetbrains.restClient` |
| Build tools | `org.jetbrains.idea.maven`, `com.android.tools.gradle.dcl` |
| AI / ML ranking | `com.intellij.completion.ml.ranking`, `com.intellij.findusages.ml`, `com.intellij.searcheverywhere.ml`, `org.jetbrains.completion.full.line` |
| Language packs | `com.intellij.ja`, `com.intellij.ko`, `com.intellij.zh` |
| Alternative keymaps | `com.intellij.plugins.eclipsekeymap`, `com.intellij.plugins.netbeanskeymap`, `com.intellij.plugins.visualstudiokeymap` |
| Cloud / remote | `com.intellij.settingsSync`, `com.jetbrains.remoteDevServer`, `com.jetbrains.remoteDevelopment`, `com.jetbrains.station` |
| Containers | `Docker` |
| Data science | `intellij.jupyter`, `org.jetbrains.plugins.kotlin.jupyter`, `intellij.grid.plugin`, `com.intellij.notebooks.core` |
| Config / frameworks | `com.intellij.configurationScript`, `idea.plugin.protoeditor`, `intellij.ktor`, `com.intellij.jsonpath`, `org.editorconfig.editorconfigjetbrains` |
| Templates | `com.intellij.velocity`, `com.intellij.freemarker` |
| AOP / scheduling | `com.intellij.aop`, `com.intellij.cron` |
| Profiling / search | `com.intellij.LineProfiler`, `org.jetbrains.idea.reposearch` |
| Diagrams / visualization | `com.intellij.diagram`, `com.intellij.debugger.collections.visualizer` |
| Bytecode / streams | `ByteCodeViewer`, `XPathView`, `org.jetbrains.debugger.streams` |
| Testing extras | `Coverage`, `TestNG-J` |
| Platform / misc | `com.intellij.code.provenance`, `com.intellij.copyright`, `com.intellij.dev`, `com.intellij.platform.daemon`, `com.intellij.platform.images`, `com.intellij.modules.json`, `com.intellij.compose`, `com.jetbrains.performancePlugin`, `com.jetbrains.performancePlugin.async`, `com.jetbrains.sh`, `Lombook Plugin` |
| Other | `training`, `com.intellij.tasks`, `com.intellij.stylelint`, `tanvd.grazi`, `org.intellij.groovy.live.templates`, `org.intellij.plugins.markdown`, `org.intellij.qodana`, `org.jetbrains.idea.eclipse`, `org.jetbrains.plugins.github`, `org.jetbrains.plugins.gitlab`, `org.jetbrains.plugins.javaFX`, `org.jetbrains.plugins.textmate`, `org.jetbrains.plugins.vue`, `org.jetbrains.plugins.yaml`, `org.jetbrains.security.package-checker` |

> **Spring Boot developers:** Re-enable via **Settings → Plugins**. Minimum set: `com.intellij.spring`, `com.intellij.spring.boot`, `org.jetbrains.plugins.yaml`.

---

## Reverting

Before making any changes, the script saves a timestamped backup inside your IDEA config directory. The exact path is printed at the end of the run:

```
✓ Backup saved → /Users/you/Library/Application Support/JetBrains/IntelliJIdea2026.1/.lean-backup-20260425-123456
```

### Restore from backup (recommended)

```bash
# macOS
cp -r "$HOME/Library/Application Support/JetBrains/IntelliJIdea2026.1/.lean-backup-YYYYMMDD-HHMMSS/"* \
      "$HOME/Library/Application Support/JetBrains/IntelliJIdea2026.1/"

# Linux
cp -r "$HOME/.config/JetBrains/IntelliJIdea2026.1/.lean-backup-YYYYMMDD-HHMMSS/"* \
      "$HOME/.config/JetBrains/IntelliJIdea2026.1/"
```

Replace `YYYYMMDD-HHMMSS` with the timestamp from the script output. Then restart IDEA.

### Remove the files manually

If the backup is gone or you just want a clean slate, delete the three files the script created. IDEA will fall back to its built-in defaults for each one on next launch.

**macOS / Linux:**
```bash
IDEA_CONFIG="$HOME/Library/Application Support/JetBrains/IntelliJIdea2026.1"   # macOS
# IDEA_CONFIG="$HOME/.config/JetBrains/IntelliJIdea2026.1"                     # Linux

rm "$IDEA_CONFIG/idea.vmoptions"
rm "$IDEA_CONFIG/disabled_plugins.txt"
rm "$IDEA_CONFIG/options/ide.general.xml"
```

**Windows (PowerShell):**
```powershell
$cfg = "$env:APPDATA\JetBrains\IntelliJIdea2026.1"
Remove-Item "$cfg\idea.vmoptions"
Remove-Item "$cfg\disabled_plugins.txt"
Remove-Item "$cfg\options\ide.general.xml"
```

Restart IDEA after either approach.

---

## Reduce Gradle daemon memory too

The IDE process is only part of the RAM picture. Gradle spawns two additional JVMs: the build daemon and the Kotlin compilation daemon. Copy `gradle.properties.example` into your project:

```bash
cp gradle.properties.example your-project/gradle.properties
```

This caps the Gradle daemon at 1 GB and the Kotlin daemon at 768 MB — enough for most medium Kotlin/JVM projects without OOM errors.

---

## Memory breakdown (before / after)

| Process | Before | After |
|---------|--------|-------|
| IntelliJ IDE heap | up to 2 GB | capped at 1 GB |
| Code cache (off-heap) | 512 MB | 240 MB |
| Gradle build daemon | uncapped | capped at 1 GB |
| Kotlin compilation daemon | uncapped | capped at 768 MB |

A medium Kotlin/Gradle project typically uses ~800 MB for the IDE process after these changes, down from 1.5–2 GB.

### JVM flags applied (`idea.vmoptions`)

```
-Xms64m
-Xmx1024m
-XX:ReservedCodeCacheSize=240m
-XX:SoftRefLRUPolicyMSPerMB=25
-XX:+UseStringDeduplication
-XX:G1ReservePercent=5
-XX:InitiatingHeapOccupancyPercent=35
-Didea.cycle.buffer.size=disabled
```

`G1ReservePercent=5` frees ~50 MB of the G1 emergency reserve. `InitiatingHeapOccupancyPercent=35` triggers concurrent GC earlier (at 35% heap fill instead of the default 45%), reducing long pauses during indexing.

---

## Customising the plugin list

`config/disabled_plugins.txt` is intentionally opinionated for Kotlin/Java/Gradle-only development. If you need a plugin that's in the list (e.g. `com.intellij.database` for SQL tools), just remove that line before running `apply.sh`.

To find a plugin's ID: **Settings → Plugins → right-click a plugin → Copy Plugin ID**.

---

## Compatibility

| IDEA version | Tested |
|-------------|--------|
| 2026.1 | ✅ |
| 2025.3 | ✅ (expected) |
| 2025.2 and older | Likely works; plugin IDs may differ |

Community Edition (IDEA CE) is not supported — it ships a different plugin set and some IDs will not match.

---

## How "Invalidate Caches" is avoided

The biggest trigger for cache corruption is external tools (AI CLI agents, build scripts) modifying files while IDEA's Virtual File System hasn't seen the change. Two registry settings address this:

- `isSyncOnFrameActivation` — IDEA rescans modified files when its window regains focus
- `isSaveOnFrameDeactivation` — IDEA flushes open editor buffers when focus is lost

Both are set to `true` by SpellStartupActivity (if you use the companion plugin). For the standalone script they can be set via **Settings → Appearance & Behavior → System Settings**.

Also make sure your Gradle project's `build/` directories are marked **Excluded** in Project Structure (⌘;) — this prevents IDEA from indexing thousands of `.class` files that change on every build.

---

## Recommended manual settings

These are per-user preferences that the script cannot write. Set them once after running `apply.sh`.

### Turn off auto-import (Settings → Editor → General → Auto Import)

With AI agents writing code, IDEA's background import management creates conflicts — it silently adds or removes imports while the agent is mid-edit, causing undo confusion and dirty diffs.

- **Java**: uncheck "Add unambiguous imports on the fly" and "Optimize imports on the fly"
- **Kotlin**: same two options under the Kotlin tab

### Turn off Git auto-fetch (Settings → Version Control → Git)

IDEA polls the remote every few minutes by default. If you're running `git fetch` / `git pull` explicitly through Claude Code or your terminal, this is redundant background network traffic and VFS churn.

- Uncheck **"Auto fetch"**

---

## License

MIT
