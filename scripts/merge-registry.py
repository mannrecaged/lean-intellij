#!/usr/bin/env python3
"""
Merges lean-intellij registry entries into an existing IDEA options/ide.general.xml.
Preserves all existing entries; only adds or updates the lean-intellij keys.

Usage:
    python3 merge-registry.py <target-ide.general.xml> <source-ide.general.xml>
"""
import sys
import os

try:
    import xml.etree.ElementTree as ET
except ImportError:
    print("Error: Python's xml.etree module is not available.", file=sys.stderr)
    sys.exit(1)


def merge(target_path: str, source_path: str) -> None:
    # Parse source entries to merge in
    src_tree = ET.parse(source_path)
    src_comp = src_tree.getroot().find("./component[@name='Registry']")
    if src_comp is None:
        return  # nothing to merge
    new_entries: dict[str, dict] = {
        e.get("key"): dict(e.attrib) for e in src_comp.findall("entry")
    }

    # Parse or create target
    if os.path.exists(target_path):
        ET.register_namespace("", "")
        tgt_tree = ET.parse(target_path)
        tgt_root = tgt_tree.getroot()
    else:
        tgt_root = ET.Element("application")
        tgt_tree = ET.ElementTree(tgt_root)

    tgt_comp = tgt_root.find("./component[@name='Registry']")
    if tgt_comp is None:
        tgt_comp = ET.SubElement(tgt_root, "component")
        tgt_comp.set("name", "Registry")

    existing = {e.get("key"): e for e in tgt_comp.findall("entry")}
    for key, attrs in new_entries.items():
        if key in existing:
            # Update value; preserve existing source attribute
            existing[key].set("value", attrs["value"])
        else:
            elem = ET.SubElement(tgt_comp, "entry")
            for k, v in attrs.items():
                elem.set(k, v)

    # Pretty-print and write
    _indent(tgt_root)
    # ElementTree.write doesn't add the XML declaration or handle the root tag cleanly,
    # so we write manually to match IDEA's expected format.
    lines = ["<application>"]
    for child in tgt_root:
        lines.append(_elem_to_str(child, indent=2))
    lines.append("</application>")
    with open(target_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")


def _indent(elem: ET.Element, level: int = 0) -> None:
    pad = "\n" + "  " * level
    if len(elem):
        elem.text = pad + "  "
        for child in elem:
            _indent(child, level + 1)
        child.tail = pad  # type: ignore[assignment]
    elem.tail = pad if level else "\n"


def _elem_to_str(elem: ET.Element, indent: int = 0) -> str:
    pad = " " * indent
    attrs = "".join(f' {k}="{v}"' for k, v in elem.attrib.items())
    if len(elem) == 0 and not elem.text:
        return f"{pad}<{elem.tag}{attrs} />"
    inner = ""
    if elem.text and elem.text.strip():
        inner = elem.text.strip()
    child_lines = [_elem_to_str(c, indent + 2) for c in elem]
    if child_lines:
        return (
            f"{pad}<{elem.tag}{attrs}>\n"
            + "\n".join(child_lines)
            + f"\n{pad}</{elem.tag}>"
        )
    return f"{pad}<{elem.tag}{attrs}>{inner}</{elem.tag}>"


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <target> <source>", file=sys.stderr)
        sys.exit(1)
    merge(sys.argv[1], sys.argv[2])
    print(f"✓ Registry entries merged into {sys.argv[1]}")
