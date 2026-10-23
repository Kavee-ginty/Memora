from pathlib import Path

from docx import Document
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Pt, RGBColor

from build_ui_spec_docx import (
    BORDER,
    MUTED,
    OCEAN,
    add_inline,
    add_markdown,
    border,
    margins,
    shade,
    style_document,
)


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "docs" / "specifications" / "Memora_App_Flow_and_Screen_State_Specification.md"
OUTPUT = ROOT / "docs" / "specifications" / "Memora_App_Flow_and_Screen_State_Specification.docx"
BLACK = "000000"


def apply_identity(doc):
    for name in ("Title", "Heading 1", "Heading 2", "Heading 3"):
        doc.styles[name].font.color.rgb = RGBColor.from_string(BLACK)

    header = doc.sections[0].header.paragraphs[0]
    header.text = "MEMORA  /  APP FLOW AND SCREEN STATE SPECIFICATION"
    run = header.runs[0]
    run.font.name, run.font.size, run.font.bold = "Exo", Pt(8), True
    run.font.color.rgb = RGBColor.from_string(BLACK)

    footer = doc.sections[0].footer.paragraphs[0]
    footer.clear()
    footer.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    run = footer.add_run("Page ")
    run.font.name, run.font.size = "Inter", Pt(8)
    run.font.color.rgb = RGBColor.from_string(MUTED)
    field = OxmlElement("w:fldSimple")
    field.set(qn("w:instr"), "PAGE")
    footer._p.append(field)


def add_cover(doc):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(96)
    r = p.add_run("Memora App Flow and\nScreen State Specification")
    r.font.name, r.font.size, r.font.bold = "Exo", Pt(34), True
    r.font.color.rgb = RGBColor.from_string(BLACK)

    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(8)
    r = p.add_run("Canonical route transition and recovery contract for the mobile MVP")
    r.font.name, r.font.size = "Inter", Pt(15)
    r.font.color.rgb = RGBColor.from_string(BLACK)

    table = doc.add_table(rows=4, cols=2)
    table.alignment = WD_TABLE_ALIGNMENT.LEFT
    rows = [
        ("Document", "5 of 6"),
        ("Status", "Canonical implementation specification"),
        ("Version", "1.0 - 22 October 2026"),
        ("Audience", "Mobile, backend, design, QA, accessibility, and AI coding agents"),
    ]
    for row, values in zip(table.rows, rows):
        for cell in row.cells:
            border(cell, BORDER)
            margins(cell, 110)
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
        shade(row.cells[0], OCEAN)
        label = row.cells[0].paragraphs[0].add_run(values[0])
        label.font.name, label.bold = "Exo", True
        label.font.color.rgb = RGBColor.from_string(BLACK)
        add_inline(row.cells[1].paragraphs[0], values[1])

    doc.add_paragraph().add_run().add_break(WD_BREAK.PAGE)
    doc.add_paragraph("How to use this specification", style="Heading 1")
    for text in (
        "Sections 1-5 define authority, navigation, bootstrap, and guards.",
        "Sections 6-13 define the student-facing flows and deep links.",
        "Sections 14-19 define offline behavior, restoration, accessibility, state ownership, and telemetry.",
        "Sections 20-24 define acceptance, traceability, implementation order, completion, and open decisions.",
    ):
        add_inline(doc.add_paragraph(style="List Bullet"), text)
    p = doc.add_paragraph()
    p.add_run("Authority rule: ").bold = True
    add_inline(p, "Use this document for routes, transitions, screen states, retries, and interruption recovery. Use the UI/UX specification and source PNGs for presentation.")
    doc.add_paragraph().add_run().add_break(WD_BREAK.PAGE)


def build():
    doc = Document()
    style_document(doc)
    apply_identity(doc)
    add_cover(doc)
    add_markdown(doc, SOURCE.read_text(encoding="utf-8"))
    props = doc.core_properties
    props.title = "Memora App Flow and Screen State Specification"
    props.subject = "Canonical route, transition, and recovery contract for Memora"
    props.author = "Memora"
    props.keywords = "Memora, Flutter, routes, screen state, offline, deep links"
    doc.save(OUTPUT)
    print(OUTPUT)


if __name__ == "__main__":
    build()
