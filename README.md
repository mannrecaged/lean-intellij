# lean-intellij

A one-command setup that makes IntelliJ IDEA Ultimate leaner and faster for **Kotlin / Java / Gradle** development — without switching to a different IDE.

Works by writing three files into your existing IDEA config directory:

| File | What it does |
|------|-------------|
| `idea.vmoptions` | Cuts default JVM heap from 2 GB → 1 GB; tunes GC and code cache |
| `disabled_plugins.txt` | Stops 86 built-in plugins from loading (Spring, Docker, Angular, Maven, localization packs, etc.) |
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

Everything else — 86 plugins — is disabled.

---

## What gets disabled (86 plugins)

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
| Diagrams / visualization | `com.intellij.diagram`, `com.intellij.debugger.collections.visualizer` |
| Bytecode / streams | `ByteCodeViewer`, `XPathView`, `org.jetbrains.debugger.streams` |
| Testing extras | `Coverage`, `TestNG-J` |
| Platform / misc | `com.intellij.code.provenance`, `com.intellij.copyright`, `com.intellij.dev`, `com.intellij.platform.daemon`, `com.intellij.platform.images`, `com.intellij.modules.json`, `com.intellij.compose`, `com.jetbrains.performancePlugin`, `com.jetbrains.performancePlugin.async`, `com.jetbrains.sh`, `Lombook Plugin` |
| Other | `training`, `com.intellij.tasks`, `com.intellij.stylelint`, `tanvd.grazi`, `org.intellij.groovy.live.templates`, `org.intellij.plugins.markdown`, `org.intellij.qodana`, `org.jetbrains.idea.eclipse`, `org.jetbrains.plugins.github`, `org.jetbrains.plugins.gitlab`, `org.jetbrains.plugins.javaFX`, `org.jetbrains.plugins.textmate`, `org.jetbrains.plugins.vue`, `org.jetbrains.plugins.yaml`, `org.jetbrains.security.package-checker` |

> **Spring Boot developers:** Re-enable via **Settings → Plugins**. Minimum set: `com.intellij.spring`, `com.intellij.spring.boot`, `org.jetbrains.plugins.yaml`.

---

## Restore original settings

The script backs up your existing files before changing anything. To restore:

```bash
# macOS / Linux — path printed at end of apply.sh
cp -r "$HOME/Library/Application Support/JetBrains/IntelliJIdea2026.1/.lean-backup-YYYYMMDD-HHMMSS/"* \
      "$HOME/Library/Application Support/JetBrains/IntelliJIdea2026.1/"
```

Or just delete the three files it created:
- `idea.vmoptions` (IDEA will use built-in defaults)
- `disabled_plugins.txt` (all plugins re-enabled)
- `options/ide.general.xml` (registry reverts to defaults)

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
| Code cache (off-heap) | 512 MB | 128 MB |
| Gradle build daemon | uncapped | capped at 1 GB |
| Kotlin compilation daemon | uncapped | capped at 768 MB |

A medium Kotlin/Gradle project typically uses ~800 MB for the IDE process after these changes, down from 1.5–2 GB.

### JVM flags applied (`idea.vmoptions`)

```
-Xms64m
-Xmx1024m
-XX:ReservedCodeCacheSize=128m
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

### Troubleshooting: `./gradlew runIde` fails in 1 second

If you see: `The contents of the immutable workspace '…/transforms/…' have been modified`

An external tool (AI CLI, `find`, another Gradle process) modified Gradle's immutable transform cache. Fix:

```bash
rm -rf ~/.gradle/caches/9.3.0/transforms/<hash-from-error>
```

Then re-run. Gradle re-extracts the affected JARs on the next build.

---

## License

MIT
