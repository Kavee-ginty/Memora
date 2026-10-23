from pathlib import Path
import re

from docx import Document
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "docs" / "specifications" / "Memora_UI_UX_Design_Specification.md"
OUTPUT = ROOT / "docs" / "specifications" / "Memora_UI_UX_Design_Specification.docx"
INK, NAVY, CYAN = "1D2228", "203F59", "00AFFF"
OCEAN, SOFT, BORDER, MUTED, WHITE = "DDEEFF", "F5F9FF", "AACFEA", "566B7D", "FFFFFF"


def shade(cell, fill):
    tc_pr = cell._tc.get_or_add_tcPr()
    node = tc_pr.find(qn("w:shd"))
    if node is None:
        node = OxmlElement("w:shd")
        tc_pr.append(node)
    node.set(qn("w:fill"), fill)


def border(cell, color=BORDER):
    tc_pr = cell._tc.get_or_add_tcPr()
    borders = tc_pr.first_child_found_in("w:tcBorders")
    if borders is None:
        borders = OxmlElement("w:tcBorders")
        tc_pr.append(borders)
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        tag = "w:" + edge
        node = borders.find(qn(tag))
        if node is None:
            node = OxmlElement(tag)
            borders.append(node)
        node.set(qn("w:val"), "single")
        node.set(qn("w:sz"), "6")
        node.set(qn("w:color"), color)


def margins(cell, value=90):
    tc_pr = cell._tc.get_or_add_tcPr()
    tc_mar = tc_pr.first_child_found_in("w:tcMar")
    if tc_mar is None:
        tc_mar = OxmlElement("w:tcMar")
        tc_pr.append(tc_mar)
    for side in ("top", "start", "bottom", "end"):
        node = tc_mar.find(qn("w:" + side))
        if node is None:
            node = OxmlElement("w:" + side)
            tc_mar.append(node)
        node.set(qn("w:w"), str(value))
        node.set(qn("w:type"), "dxa")


def repeat_header(row):
    tr_pr = row._tr.get_or_add_trPr()
    node = OxmlElement("w:tblHeader")
    node.set(qn("w:val"), "true")
    tr_pr.append(node)


def keep_with_next(paragraph):
    p_pr = paragraph._p.get_or_add_pPr()
    p_pr.append(OxmlElement("w:keepNext"))


def add_inline(paragraph, text):
    token_re = re.compile(r"(`[^`]+`|\*\*[^*]+\*\*|\*[^*]+\*)")
    pos = 0
    for match in token_re.finditer(text):
        if match.start() > pos:
            paragraph.add_run(text[pos:match.start()])
        token = match.group(0)
        if token.startswith("`"):
            run = paragraph.add_run(token[1:-1])
            run.font.name = "Consolas"
            run.font.size = Pt(8.5)
            run.font.color.rgb = RGBColor.from_string(NAVY)
        elif token.startswith("**"):
            paragraph.add_run(token[2:-2]).bold = True
        else:
            paragraph.add_run(token[1:-1]).italic = True
        pos = match.end()
    if pos < len(text):
        paragraph.add_run(text[pos:])


def style_document(doc):
    section = doc.sections[0]
    section.page_width, section.page_height = Inches(8.5), Inches(11)
    section.top_margin = section.bottom_margin = Inches(0.72)
    section.left_margin = section.right_margin = Inches(0.78)
    section.header_distance, section.footer_distance = Inches(0.28), Inches(0.3)

    normal = doc.styles["Normal"]
    normal.font.name, normal.font.size = "Inter", Pt(9.5)
    normal.font.color.rgb = RGBColor.from_string(INK)
    normal.paragraph_format.space_after = Pt(5)
    normal.paragraph_format.line_spacing = 1.08

    for name, size, color, before, after in (
        ("Title", 30, INK, 0, 12),
        ("Heading 1", 20, NAVY, 16, 8),
        ("Heading 2", 15, NAVY, 12, 6),
        ("Heading 3", 11.5, INK, 9, 4),
    ):
        st = doc.styles[name]
        st.font.name, st.font.size, st.font.bold = "Exo", Pt(size), True
        st.font.color.rgb = RGBColor.from_string(color)
        st.paragraph_format.space_before, st.paragraph_format.space_after = Pt(before), Pt(after)
        st.paragraph_format.keep_with_next = True

    header = section.header.paragraphs[0]
    header.text = "MEMORA  /  UI/UX DESIGN SPECIFICATION"
    run = header.runs[0]
    run.font.name, run.font.size, run.font.bold = "Exo", Pt(8), True
    run.font.color.rgb = RGBColor.from_string(NAVY)

    footer = section.footer.paragraphs[0]
    footer.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    run = footer.add_run("Page ")
    run.font.name, run.font.size = "Inter", Pt(8)
    run.font.color.rgb = RGBColor.from_string(MUTED)
    field = OxmlElement("w:fldSimple")
    field.set(qn("w:instr"), "PAGE")
    footer._p.append(field)


def add_cover(doc):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(100)
    r = p.add_run("Memora UI/UX\nDesign Specification")
    r.font.name, r.font.size, r.font.bold = "Exo", Pt(34), True
    r.font.color.rgb = RGBColor.from_string(INK)

    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(8)
    r = p.add_run("Canonical implementation brief for the student-facing mobile MVP")
    r.font.name, r.font.size = "Inter", Pt(15)
    r.font.color.rgb = RGBColor.from_string(NAVY)

    table = doc.add_table(rows=4, cols=2)
    table.alignment = WD_TABLE_ALIGNMENT.LEFT
    rows = [
        ("Document", "3 of 6"),
        ("Status", "Canonical implementation brief"),
        ("Audience", "Design, engineering, QA, and AI coding agents"),
        ("Source", "Memora UI screens and UI/UX visual audit"),
    ]
    for row, values in zip(table.rows, rows):
        for cell in row.cells:
            border(cell)
            margins(cell, 110)
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
        shade(row.cells[0], OCEAN)
        a = row.cells[0].paragraphs[0].add_run(values[0])
        a.font.name, a.bold = "Exo", True
        a.font.color.rgb = RGBColor.from_string(NAVY)
        add_inline(row.cells[1].paragraphs[0], values[1])

    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(92)
    r = p.add_run("One continuous seabed. One reef per subject. Short missions that protect memory without pressure.")
    r.font.name, r.font.size, r.font.bold = "Exo", Pt(14), True
    r.font.color.rgb = RGBColor.from_string(CYAN)
    p.add_run().add_break(WD_BREAK.PAGE)

    doc.add_paragraph("How to use this brief", style="Heading 1")
    for text in (
        "Sections 1–8 define the shared experience system and flows.",
        "Section 9 is the screen-by-screen implementation contract.",
        "Sections 10–13 define gamification, language, accessibility, and state handling.",
        "Sections 14–18 provide acceptance criteria, source mapping, and agent handoff guidance.",
    ):
        add_inline(doc.add_paragraph(style="List Bullet"), text)
    p = doc.add_paragraph()
    p.add_run("Authority rule: ").bold = True
    add_inline(p, "Follow this specification when a source PNG or the earlier visual audit is ambiguous.")
    p.add_run().add_break(WD_BREAK.PAGE)


def add_markdown(doc, markdown):
    lines = markdown.splitlines()
    i = 0
    while i < len(lines) and not re.match(r"^## 1(?:\.|\s)", lines[i]):
        i += 1

    while i < len(lines):
        line = lines[i]
        if not line.strip():
            i += 1
            continue

        if line.startswith("```mermaid"):
            code = []
            i += 1
            while i < len(lines) and not lines[i].startswith("```"):
                code.append(lines[i].strip())
                i += 1
            i += 1
            readable = []
            for raw in code:
                if not raw or raw.startswith("flowchart"):
                    continue
                raw = re.sub(r"[A-Z][A-Z0-9]*\[([^]]+)\]", r"\1", raw)
                raw = re.sub(r"[A-Z][A-Z0-9]*\{([^}]+)\}", r"\1", raw)
                raw = raw.replace("-->", " → ")
                raw = re.sub(r"\s*--\s*([^\-]+)\s*", r" — \1 → ", raw)
                readable.append(raw)
            table = doc.add_table(rows=1, cols=1)
            cell = table.cell(0, 0)
            shade(cell, SOFT)
            border(cell)
            margins(cell, 130)
            p = cell.paragraphs[0]
            r = p.add_run("Flow summary\n")
            r.font.name, r.bold = "Exo", True
            r.font.color.rgb = RGBColor.from_string(NAVY)
            p.add_run("\n".join(readable))
            continue

        if line.startswith("|") and i + 1 < len(lines) and re.match(r"^\|\s*:?-+", lines[i + 1]):
            rows = [[c.strip() for c in line.strip().strip("|").split("|")]]
            i += 2
            while i < len(lines) and lines[i].startswith("|"):
                rows.append([c.strip() for c in lines[i].strip().strip("|").split("|")])
                i += 1
            cols = max(len(row) for row in rows)
            table = doc.add_table(rows=len(rows), cols=cols)
            table.alignment = WD_TABLE_ALIGNMENT.CENTER
            for r_idx, row_data in enumerate(rows):
                for c_idx in range(cols):
                    cell = table.cell(r_idx, c_idx)
                    border(cell)
                    margins(cell)
                    if r_idx == 0:
                        shade(cell, NAVY)
                    elif r_idx % 2 == 0:
                        shade(cell, SOFT)
                    p = cell.paragraphs[0]
                    add_inline(p, row_data[c_idx] if c_idx < len(row_data) else "")
                    for run in p.runs:
                        run.font.size = Pt(8.2)
                        if r_idx == 0:
                            run.bold = True
                            run.font.color.rgb = RGBColor.from_string(WHITE)
            repeat_header(table.rows[0])
            continue

        heading = re.match(r"^(#{1,3})\s+(.+)$", line)
        if heading:
            p = doc.add_paragraph(style=f"Heading {len(heading.group(1))}")
            add_inline(p, heading.group(2))
            i += 1
            continue

        bullet = re.match(r"^-\s+(.+)$", line)
        numbered = re.match(r"^\d+\.\s+(.+)$", line)
        if bullet or numbered:
            p = doc.add_paragraph(style="List Bullet" if bullet else "List Number")
            add_inline(p, (bullet or numbered).group(1))
            i += 1
            continue

        if line.startswith("> "):
            p = doc.add_paragraph()
            p.paragraph_format.left_indent = Inches(0.28)
            p.paragraph_format.right_indent = Inches(0.16)
            add_inline(p, line[2:])
            for run in p.runs:
                run.italic = True
                run.font.color.rgb = RGBColor.from_string(NAVY)
            i += 1
            continue

        parts = [line.strip()]
        i += 1
        while i < len(lines):
            nxt = lines[i]
            if (not nxt.strip() or nxt.startswith("#") or nxt.startswith("-") or
                    re.match(r"^\d+\.\s", nxt) or nxt.startswith("|") or
                    nxt.startswith(">") or nxt.startswith("```")):
                break
            parts.append(nxt.strip())
            i += 1
        add_inline(doc.add_paragraph(), " ".join(parts))


def build():
    doc = Document()
    style_document(doc)
    add_cover(doc)
    add_markdown(doc, SOURCE.read_text(encoding="utf-8"))
    props = doc.core_properties
    props.title = "Memora UI/UX Design Specification"
    props.subject = "Canonical implementation brief for Memora's student-facing mobile MVP"
    props.author = "Memora"
    props.keywords = "Memora, UI, UX, accessibility, design system, implementation"
    doc.save(OUTPUT)
    print(OUTPUT)


if __name__ == "__main__":
    build()
