# lean-intellij

A one-command setup that makes IntelliJ IDEA Ultimate leaner and faster for **Kotlin / Java / Gradle** development — without switching to a different IDE.

Works by writing three files into your existing IDEA config directory:

| File | What it does |
|------|-------------|
| `idea.vmoptions` | Cuts default JVM heap from 2 GB → 1 GB; shrinks code cache from 512 MB → 128 MB |
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
| `com.intellij.mcpServer` | MCP server for AI agent tools |
| `intellij.platform.ijent.impl` | WSL and SSH remote development |

Everything else — Spring, Docker, Angular, Maven, Vue, Jupyter, Markdown, EclipseKeymap, etc. — is disabled.

---

## What gets disabled (86 plugins)

<details>
<summary>Click to expand full list</summary>

| Plugin | Category |
|--------|----------|
| `AngularJS`, `JavaScript`, `HtmlTools`, `com.intellij.css`, `com.intellij.react`, `intellij.prettierJS`, `tslint`, `AngularJS`, `intellij.vitejs`, `intellij.webpack` | Web front-end |
| `com.intellij.spring`, `com.intellij.spring.boot`, `com.intellij.spring.boot.initializr`, `com.intellij.thymeleaf` | Spring framework |
| `com.intellij.javaee`, `com.intellij.javaee.el`, `com.intellij.jpa.jpb.model` | Jakarta EE |
| `org.jetbrains.idea.maven` | Maven (use Gradle instead) |
| `Docker` | Docker integration |
| `com.intellij.database` | Database/SQL tools |
| `com.intellij.ja`, `com.intellij.ko`, `com.intellij.zh` | Language packs (Japanese, Korean, Chinese) |
| `com.intellij.plugins.eclipsekeymap`, `com.intellij.plugins.netbeanskeymap`, `com.intellij.plugins.visualstudiokeymap` | Alternative keymaps |
| `training` | IDE interactive learning |
| `com.intellij.settingsSync` | JetBrains cloud settings sync |
| `org.jetbrains.plugins.github`, `org.jetbrains.plugins.gitlab` | GitHub / GitLab pull request UI |
| `org.intellij.plugins.markdown` | Markdown preview |
| `intellij.jupyter`, `org.jetbrains.plugins.kotlin.jupyter` | Jupyter notebook support |
| `ByteCodeViewer` | Bytecode viewer tool window |
| `Coverage` | Code coverage integration |
| `com.intellij.diagram` | UML diagrams |
| `com.intellij.tasks` | Issue tracker integration |
| `com.intellij.copyright` | Copyright header management |
| …and more | See `config/disabled_plugins.txt` |

</details>

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
- `options/ide.general.xml` entries (registry reverts to defaults)

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

## License

MIT
