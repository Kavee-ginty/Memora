from math import atan2, cos, sin
from pathlib import Path
import textwrap

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "docs" / "project-management" / "Memora_Development_Network_Diagram.png"
WIDTH, HEIGHT = 4800, 2600

TASKS = {
    "T01": ("Repo baseline", 2, []),
    "T02": ("CI and environments", 3, ["T01"]),
    "T03": ("Flutter system and shell", 5, ["T01"]),
    "T04": ("Database migrations", 6, ["T01"]),
    "T05": ("OpenAPI pipeline", 4, ["T01"]),
    "T06": ("Identity backend", 4, ["T02", "T04", "T05"]),
    "T07": ("Mobile auth and routes", 5, ["T03", "T05", "T06"]),
    "T08": ("Curriculum graph seed", 5, ["T04"]),
    "T09": ("Ingestion backend", 7, ["T05", "T06", "T08"]),
    "T10": ("Ingestion mobile", 6, ["T07", "T09"]),
    "T11": ("Memory engine", 7, ["T08"]),
    "T12": ("Questions and grading", 7, ["T08", "T05"]),
    "T13": ("Mission backend", 7, ["T06", "T11", "T12"]),
    "T14": ("Mission mobile", 7, ["T07", "T13"]),
    "T15": ("Progress backend", 5, ["T11", "T13"]),
    "T16": ("Progress mobile", 5, ["T07", "T15"]),
    "T17": ("Profile backend", 4, ["T06"]),
    "T18": ("Profile mobile", 4, ["T07", "T17"]),
    "T19": ("Push and deep links", 4, ["T07", "T17"]),
    "T20": ("Privacy backend", 5, ["T06", "T04"]),
    "T21": ("Privacy mobile", 3, ["T07", "T20"]),
    "T22": ("Offline and idempotency", 6, ["T09", "T13", "T07"]),
    "T23": ("Security and observability", 5, ["T02", "T09", "T13", "T17", "T20"]),
    "T24": ("Physics pilot content", 6, ["T08", "T12"]),
    "T25": ("API and auth tests", 5, ["T09", "T13", "T15", "T17", "T20"]),
    "T26": ("End-to-end integration", 6, ["T10", "T14", "T16", "T18", "T19", "T21", "T22", "T25"]),
    "T27": ("Accessibility and visual QA", 5, ["T10", "T14", "T16", "T18", "T19", "T21"]),
    "T28": ("Load security failure tests", 5, ["T23", "T26"]),
    "T29": ("Staging and UAT", 4, ["T24", "T26", "T27", "T28"]),
    "T30": ("Pilot fixes and RC", 5, ["T29"]),
    "T31": ("Production pilot", 2, ["T30"]),
}

POSITIONS = {
    "T01": (190, 1320),
    "T02": (600, 280), "T03": (600, 690), "T04": (600, 1190), "T05": (600, 1740),
    "T06": (1030, 500), "T08": (1030, 1320),
    "T17": (1470, 160), "T07": (1470, 430), "T20": (1470, 760), "T09": (1470, 1060),
    "T11": (1470, 1370), "T12": (1470, 1680),
    "T18": (1930, 160), "T10": (1930, 430), "T19": (1930, 700), "T21": (1930, 970),
    "T13": (1930, 1350), "T24": (1930, 1980),
    "T14": (2390, 600), "T15": (2390, 1160), "T22": (2390, 1500), "T23": (2390, 1900),
    "T16": (2830, 920), "T25": (2830, 1360),
    "T27": (3260, 630), "T26": (3260, 1160),
    "T28": (3630, 1160), "T29": (3970, 1160), "T30": (4280, 1160), "T31": (4590, 1160),
}

CRITICAL = {"T01", "T04", "T08", "T11", "T12", "T13", "T15", "T16", "T25", "T26", "T28", "T29", "T30", "T31"}


def font(size, bold=False):
    name = "arialbd.ttf" if bold else "arial.ttf"
    path = Path("C:/Windows/Fonts") / name
    return ImageFont.truetype(str(path), size)


def cubic_points(start, end, steps=30):
    x1, y1 = start
    x2, y2 = end
    bend = max(80, (x2 - x1) * 0.48)
    c1, c2 = (x1 + bend, y1), (x2 - bend, y2)
    points = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        x = u**3 * x1 + 3 * u**2 * t * c1[0] + 3 * u * t**2 * c2[0] + t**3 * x2
        y = u**3 * y1 + 3 * u**2 * t * c1[1] + 3 * u * t**2 * c2[1] + t**3 * y2
        points.append((x, y))
    return points


def draw_arrow(draw, source, target, critical):
    radius = 58
    sx, sy = POSITIONS[source]
    tx, ty = POSITIONS[target]
    angle = atan2(ty - sy, tx - sx)
    start = (sx + radius * cos(angle), sy + radius * sin(angle))
    end = (tx - radius * cos(angle), ty - radius * sin(angle))
    points = cubic_points(start, end)
    color = "#C62828" if critical else "#7890A4"
    width = 9 if critical else 4
    draw.line(points, fill=color, width=width, joint="curve")
    x, y = points[-1]
    a = atan2(points[-1][1] - points[-3][1], points[-1][0] - points[-3][0])
    size = 23 if critical else 16
    wing = 0.55
    arrow = [
        (x, y),
        (x - size * cos(a - wing), y - size * sin(a - wing)),
        (x - size * cos(a + wing), y - size * sin(a + wing)),
    ]
    draw.polygon(arrow, fill=color)


def build():
    image = Image.new("RGB", (WIDTH, HEIGHT), "#FAFCFE")
    draw = ImageDraw.Draw(image)

    draw.text((170, 65), "Memora Development Project Network", font=font(76, True), fill="#13293D")
    draw.text((175, 155), "PERT / CPM precedence network  |  59 focused workdays  |  four zero-float paths", font=font(31), fill="#52697A")

    phases = [
        (120, 900, "FOUNDATION"),
        (900, 1800, "CORE SERVICES"),
        (1800, 3000, "FEATURE DELIVERY"),
        (3000, 3750, "INTEGRATION"),
        (3750, 4740, "RELEASE"),
    ]
    for left, right, title in phases:
        draw.rounded_rectangle((left, 225, right, 2360), radius=28, fill="#FFFFFF", outline="#D8E2EA", width=3)
        box = draw.textbbox((0, 0), title, font=font(24, True))
        draw.text(((left + right - (box[2] - box[0])) / 2, 244), title, font=font(24, True), fill="#6A7F90")

    dependencies = [(dep, task) for task, (_, _, deps) in TASKS.items() for dep in deps]
    for source, target in dependencies:
        if not (source in CRITICAL and target in CRITICAL):
            draw_arrow(draw, source, target, False)
    for source, target in dependencies:
        if source in CRITICAL and target in CRITICAL:
            draw_arrow(draw, source, target, True)

    for task, (label, days, _) in TASKS.items():
        x, y = POSITIONS[task]
        critical = task in CRITICAL
        fill = "#FFF1F1" if critical else "#EAF5FF"
        outline = "#C62828" if critical else "#2878A5"
        if task == "T31":
            fill, outline = "#E9F7EF", "#238636"
        draw.ellipse((x - 58, y - 58, x + 58, y + 58), fill=fill, outline=outline, width=8 if critical else 5)
        id_box = draw.textbbox((0, 0), task, font=font(30, True))
        draw.text((x - (id_box[2] - id_box[0]) / 2, y - 20), task, font=font(30, True), fill="#172B3A")

        lines = textwrap.wrap(label, width=22)
        label_y = y + 72
        for line in lines[:2]:
            box = draw.textbbox((0, 0), line, font=font(24, True))
            draw.text((x - (box[2] - box[0]) / 2, label_y), line, font=font(24, True), fill="#172B3A")
            label_y += 30
        duration = f"{days}d"
        box = draw.textbbox((0, 0), duration, font=font(22))
        draw.text((x - (box[2] - box[0]) / 2, label_y + 3), duration, font=font(22), fill="#607587")

    draw.rounded_rectangle((170, 2410, 1110, 2530), radius=24, fill="#FFFFFF", outline="#D8E2EA", width=3)
    draw.line((215, 2458, 320, 2458), fill="#C62828", width=10)
    draw.text((345, 2432), "Critical dependency and zero-float task", font=font(25), fill="#243B4A")
    draw.line((1190, 2458, 1295, 2458), fill="#7890A4", width=5)
    draw.text((1320, 2432), "Non-critical path", font=font(25), fill="#243B4A")
    draw.text((3150, 2432), "Task duration is shown below each node", font=font(25), fill="#52697A")

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUTPUT, optimize=True)
    print(OUTPUT)


if __name__ == "__main__":
    build()
