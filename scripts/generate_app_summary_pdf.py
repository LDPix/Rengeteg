from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.pagesizes import landscape, letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    ListFlowable,
    ListItem,
    PageBreak,
    PageTemplate,
    Paragraph,
    Spacer,
)


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = ROOT / "output" / "pdf"
OUTPUT_PATH = OUTPUT_DIR / "rengeteg_app_summary.pdf"


def build_styles():
    styles = getSampleStyleSheet()
    styles.add(
        ParagraphStyle(
            name="AppTitle",
            parent=styles["Title"],
            fontName="Helvetica-Bold",
            fontSize=22,
            leading=24,
            textColor=colors.HexColor("#17321D"),
            spaceAfter=6,
        )
    )
    styles.add(
        ParagraphStyle(
            name="Meta",
            parent=styles["BodyText"],
            fontName="Helvetica",
            fontSize=9,
            leading=11,
            textColor=colors.HexColor("#47614B"),
            spaceAfter=10,
        )
    )
    styles.add(
        ParagraphStyle(
            name="Section",
            parent=styles["Heading2"],
            fontName="Helvetica-Bold",
            fontSize=11,
            leading=13,
            textColor=colors.HexColor("#17321D"),
            spaceBefore=4,
            spaceAfter=4,
        )
    )
    styles.add(
        ParagraphStyle(
            name="BodyCompact",
            parent=styles["BodyText"],
            fontName="Helvetica",
            fontSize=9,
            leading=11,
            textColor=colors.HexColor("#222222"),
            spaceAfter=5,
        )
    )
    styles.add(
        ParagraphStyle(
            name="BulletCompact",
            parent=styles["BodyText"],
            fontName="Helvetica",
            fontSize=8.8,
            leading=10.6,
            textColor=colors.HexColor("#222222"),
        )
    )
    styles.add(
        ParagraphStyle(
            name="FooterNote",
            parent=styles["BodyText"],
            fontName="Helvetica-Oblique",
            fontSize=7.4,
            leading=9,
            textColor=colors.HexColor("#5A5A5A"),
            spaceBefore=4,
        )
    )
    return styles


def bullet_list(items, style, left_indent=14, bullet_color="#17321D"):
    return ListFlowable(
        [
            ListItem(Paragraph(item, style), leftIndent=0)
            for item in items
        ],
        bulletType="bullet",
        start="circle",
        leftIndent=left_indent,
        bulletFontName="Helvetica-Bold",
        bulletFontSize=7,
        bulletColor=colors.HexColor(bullet_color),
        spaceBefore=0,
        spaceAfter=4,
    )


def build_story(styles):
    story = []

    story.append(Paragraph("Rengeteg", styles["AppTitle"]))
    story.append(
        Paragraph(
            "Repo summary based only on local project evidence. Godot main scene: <b>Camp.tscn</b>. "
            "Autoloads: <b>GameData</b> and <b>GameState</b>. Web export preset present in <b>export_presets.cfg</b>.",
            styles["Meta"],
        )
    )

    story.append(Paragraph("What It Is", styles["Section"]))
    story.append(
        Paragraph(
            "A Godot adventure game centered on camp management, short overworld expeditions, creature binding, "
            "and turn-based battles. The project starts in camp, sends the player into authored map scenes, and "
            "returns through battle and progression loops.",
            styles["BodyCompact"],
        )
    )

    story.append(Paragraph("Who It's For", styles["Section"]))
    story.append(
        Paragraph(
            "Primary user/persona: <b>Not found in repo.</b> Inferred player: someone who likes creature collection, "
            "resource gathering, crafting, and lightweight RPG progression.",
            styles["BodyCompact"],
        )
    )

    story.append(Paragraph("What It Does", styles["Section"]))
    story.append(
        bullet_list(
            [
                "Starts at camp, which acts as the hub for party review, crafting, map selection, and venture setup.",
                "Lets players explore overworld maps with encounter zones, resource nodes, exits, and boss markers.",
                "Triggers wild battles from encounter tiles and switches into a dedicated battle scene.",
                "Supports binding weakened creatures with seals and storing overflow creatures in a box.",
                "Tracks materials, consumable items, held items, camp items, objectives, and map completion state.",
                "Generates per-run map content such as resource spawns, active encounter patches, and boss placement.",
                "Saves and loads progress through a JSON save file at <b>user://savegame.json</b>.",
            ],
            styles["BulletCompact"],
        )
    )

    story.append(Paragraph("How It Works", styles["Section"]))
    story.append(
        bullet_list(
            [
                "<b>Content/config layer:</b> <b>GameData</b> defines creatures, abilities, items, objectives, map run config, wild encounter tables, and boss config.",
                "<b>Runtime state layer:</b> <b>GameState</b> stores party, inventory, materials, current map run, pending battle context, tutorial flags, and save/load serialization.",
                "<b>Scene flow:</b> <b>Camp.tscn</b> is the main scene; camp launches overworld scenes, overworld sets pending battle data then changes to <b>Battle.tscn</b>, and battle returns to overworld or camp.",
                "<b>Overworld generation:</b> <b>MapRunService</b> reads spawn markers from map scenes, creates resource nodes, activates encounter patches, and conditionally shows bosses based on objective state.",
                "<b>Presentation:</b> scene scripts drive UI behavior while <b>WorldUI</b> applies shared panel, label, button, and resource-chip styling across camp and battle screens.",
                "<b>Persistence/export:</b> progress saves to JSON via <b>GameState</b>; a runnable web export preset targets <b>build/web/index.html</b>.",
            ],
            styles["BulletCompact"],
        )
    )

    story.append(Paragraph("How To Run", styles["Section"]))
    story.append(
        bullet_list(
            [
                "Install Godot. Repo evidence shows a local working version of <b>4.6.1</b>; exact install instructions are <b>Not found in repo</b>.",
                "From the repo root, run <b>./run_godot.sh run</b>. If Godot is not on PATH, use <b>GODOT_BIN=/path/to/godot ./run_godot.sh run</b>.",
                "For the editor, run <b>./run_godot.sh editor</b>. For a quick validation pass, run <b>./run_godot.sh headless</b>.",
            ],
            styles["BulletCompact"],
        )
    )

    story.append(Spacer(1, 0.08 * inch))
    story.append(
        Paragraph(
            "Evidence sampled from project.godot, run_godot.sh, export_presets.cfg, scenes/Camp.tscn, "
            "scenes/Battle.tscn, scenes/overworld/Overworld_Verdant.tscn, scripts/game_data.gd, "
            "scripts/game_state.gd, scripts/camp.gd, scripts/overworld.gd, scripts/battle.gd, "
            "scripts/map_run_service.gd, and scripts/ui/world_ui.gd.",
            styles["FooterNote"],
        )
    )

    return story


def add_page_chrome(canvas, doc):
    canvas.saveState()
    width, height = landscape(letter)

    canvas.setFillColor(colors.white)
    canvas.rect(0, 0, width, height, stroke=0, fill=1)

    canvas.setFillColor(colors.HexColor("#EAF0E3"))
    canvas.rect(0, height - 30, width, 30, stroke=0, fill=1)

    canvas.setStrokeColor(colors.HexColor("#A8B79F"))
    canvas.setLineWidth(1)
    canvas.line(doc.leftMargin, height - 34, width - doc.rightMargin, height - 34)

    canvas.setFillColor(colors.HexColor("#4A5B49"))
    canvas.setFont("Helvetica", 7.5)
    canvas.drawRightString(width - doc.rightMargin, 14, "One-page repo summary")
    canvas.restoreState()


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    page_size = landscape(letter)
    doc = BaseDocTemplate(
        str(OUTPUT_PATH),
        pagesize=page_size,
        leftMargin=0.5 * inch,
        rightMargin=0.5 * inch,
        topMargin=0.55 * inch,
        bottomMargin=0.38 * inch,
    )

    frame = Frame(
        doc.leftMargin,
        doc.bottomMargin,
        doc.width,
        doc.height,
        leftPadding=0,
        rightPadding=0,
        topPadding=0,
        bottomPadding=0,
        id="main",
    )
    doc.addPageTemplates([PageTemplate(id="summary", frames=[frame], onPage=add_page_chrome)])

    styles = build_styles()
    story = build_story(styles)
    doc.build(story)

    print(OUTPUT_PATH)


if __name__ == "__main__":
    main()
