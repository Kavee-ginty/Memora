from pathlib import Path

from docx import Document
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Pt, RGBColor

from build_ui_spec_docx import BORDER, MUTED, OCEAN, add_inline, add_markdown, border, margins, shade, style_document


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "docs" / "specifications" / "Memora_API_and_Integration_Contract.md"
OUTPUT = ROOT / "docs" / "specifications" / "Memora_API_and_Integration_Contract.docx"
BLACK = "000000"


def add_identity(doc):
    for name in ("Title", "Heading 1", "Heading 2", "Heading 3"):
        doc.styles[name].font.color.rgb = RGBColor.from_string(BLACK)
    header = doc.sections[0].header.paragraphs[0]
    header.text = "MEMORA  /  API AND INTEGRATION CONTRACT"
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
    r = p.add_run("Memora API and\nIntegration Contract")
    r.font.name, r.font.size, r.font.bold = "Exo", Pt(34), True
    r.font.color.rgb = RGBColor.from_string(BLACK)
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(8)
    r = p.add_run("Canonical mobile backend and provider contract for the MVP")
    r.font.name, r.font.size = "Inter", Pt(15)
    r.font.color.rgb = RGBColor.from_string(BLACK)
    table = doc.add_table(rows=4, cols=2)
    table.alignment = WD_TABLE_ALIGNMENT.LEFT
    rows = [
        ("Document", "6 of 6"),
        ("Status", "Canonical implementation specification"),
        ("Version", "1.0 - 22 October 2026"),
        ("Audience", "Mobile, backend, data, security, QA, and AI coding agents"),
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
    doc.add_paragraph("How to use this contract", style="Heading 1")
    for text in (
        "Sections 1-7 define authority, transport, authentication, errors, idempotency, and caching.",
        "Sections 8-17 define the complete student API resource surface and provider integrations.",
        "Sections 18-22 define retries, security, OpenAPI, generated clients, and contract tests.",
        "Sections 23-26 define traceability, implementation order, completion, and open decisions.",
    ):
        add_inline(doc.add_paragraph(style="List Bullet"), text)
    p = doc.add_paragraph()
    p.add_run("Authority rule: ").bold = True
    add_inline(p, "Generated OpenAPI must match this contract, and deployed API behavior must match the generated OpenAPI.")
    doc.add_paragraph().add_run().add_break(WD_BREAK.PAGE)


def build():
    doc = Document()
    style_document(doc)
    add_identity(doc)
    add_cover(doc)
    add_markdown(doc, SOURCE.read_text(encoding="utf-8"))
    props = doc.core_properties
    props.title = "Memora API and Integration Contract"
    props.subject = "Canonical API contract for Memora's student-facing MVP"
    props.author = "Memora"
    props.keywords = "Memora, FastAPI, OpenAPI, Flutter, API, integration"
    doc.save(OUTPUT)
    print(OUTPUT)


if __name__ == "__main__":
    build()
