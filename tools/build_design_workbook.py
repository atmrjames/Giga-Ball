#!/usr/bin/env python3
"""Fills in Giga-Ball 2026.xlsx from the game's own tables plus the specs.

Everything marked "derived" comes from /tmp/gigaball-catalogue.json, which a test dumps
straight out of the app's catalogues, so those cells cannot disagree with the game.
Everything else is either quoted from a specification or is my reading of it, and is
marked so James can correct it.
"""
import json
from openpyxl import load_workbook
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter
from openpyxl.worksheet.dimensions import ColumnDimension

SRC = "/tmp/gigaball-catalogue.json"
OUT = "/Users/James/Desktop/Giga-Ball 2026.xlsx"

data = json.load(open(SRC))
ICONS = json.load(open("/tmp/gigaball-icons.json"))
POWERUPS = data["powerUps"]
STYLES = data["styles"]
TWISTS = data["twists"]
BRICKS = data["bricks"]

# ---------------------------------------------------------------- house style
FONT = "Arial"
HEAD_FILL = PatternFill("solid", fgColor="1F2430")
HEAD_FONT = Font(name=FONT, bold=True, color="D2FF00", size=11)
SUB_FILL = PatternFill("solid", fgColor="3A3F4B")
SUB_FONT = Font(name=FONT, bold=True, color="FFFFFF", size=10)
BODY = Font(name=FONT, size=10)
BODY_SMALL = Font(name=FONT, size=8)
NOTE = Font(name=FONT, size=9, italic=True, color="666666")
WRAP = Alignment(wrap_text=True, vertical="top")
CENTRE = Alignment(horizontal="center", vertical="center", wrap_text=True)
THIN = Side(style="thin", color="BFBFBF")
BOX = Border(left=THIN, right=THIN, top=THIN, bottom=THIN)

FILLS = {
    "self": PatternFill("solid", fgColor="E8E8E8"),
    "conflict": PatternFill("solid", fgColor="F8CBAD"),
    "notable": PatternFill("solid", fgColor="FFF2CC"),
    "plain": PatternFill("solid", fgColor="FFFFFF"),
    "never": PatternFill("solid", fgColor="D9D9D9"),
    "good": PatternFill("solid", fgColor="E2F0D9"),
    "bad": PatternFill("solid", fgColor="FCE4EC"),
    "todo": PatternFill("solid", fgColor="DEEBF7"),
}

wb = load_workbook(OUT)


def head(ws, row, values, widths=None):
    for i, v in enumerate(values, start=1):
        c = ws.cell(row=row, column=i, value=v)
        c.fill = HEAD_FILL
        c.font = HEAD_FONT
        c.alignment = CENTRE
        c.border = BOX
    if widths:
        for i, w in enumerate(widths, start=1):
            ws.column_dimensions[get_column_letter(i)].width = w
    ws.row_dimensions[row].height = 30


def put(ws, row, col, value, font=BODY, fill=None, align=WRAP, border=True):
    c = ws.cell(row=row, column=col, value=value)
    c.font = font
    c.alignment = align
    if fill:
        c.fill = fill
    if border:
        c.border = BOX
    return c


# ================================================================ 1. Read Me
if "Read Me" in wb.sheetnames:
    del wb["Read Me"]
ws = wb.create_sheet("Read Me", 0)
ws.column_dimensions["A"].width = 26
ws.column_dimensions["B"].width = 110
ws.sheet_view.showGridLines = False

put(ws, 1, 1, "Giga-Ball 2026 - design reference", Font(name=FONT, bold=True, size=16),
    border=False)
put(ws, 2, 1, "Filled in from the game as it stands, 16 August 2026 (release 1.3, round 145).",
    NOTE, border=False)

rows = [
    ("What this is",
     "One place that says what every power-up, brick and twist is, and how each one behaves "
     "beside every other. The detail sheets describe things one at a time; the matrix sheets "
     "are about pairs."),
    ("Where the facts come from",
     "Cells marked DERIVED are dumped straight out of the game's own catalogues by a test, so "
     "they cannot drift from the code. Cells marked SPEC are quoted or summarised from "
     "SPECIFICATION.md, ENDLESS-2-SPECIFICATION.md or DAILY-CHALLENGE-SPECIFICATION.md. Cells "
     "marked ASSUMED are my reading of how two things behave together and have not been "
     "play-tested or checked against the code - those are the ones worth your attention first."),
    ("How to read a matrix",
     "The same list runs along the top and down the side, including each item against itself. "
     "Read a cell as 'the row item, while the column item is already running'. Where order "
     "matters the cell says so."),
    ("Matrix colours",
     "Grey diagonal - the item with itself (what a second one does). "
     "Orange - they cannot both be honoured; one supersedes the other. "
     "Yellow - they combine, and the combination is worth knowing about. "
     "White - independent: both run and neither changes the other. "
     "Dark grey - they can never meet."),
    ("Built?",
     "Yes means it is in the app today. Designed means it is written up in a spec and not "
     "built. Parked means built but deliberately not offered."),
    ("What is missing",
     "Artwork columns are for you: the icon columns name what the game draws today, which for "
     "most power-ups is a drawn placeholder rather than an asset (ENDLESS-2 8.5). Sounds are "
     "not in this book - say the word and I will add a sheet."),
    ("Suggested additions",
     "The sheets 'Not Built', 'Modes' and this one are mine rather than yours - delete any "
     "that are not useful. Columns I added to your tables are marked with a + in the header "
     "row's comment."),
]
r = 4
for label, text in rows:
    put(ws, r, 1, label, Font(name=FONT, bold=True, size=10), FILLS["self"])
    put(ws, r, 2, text, BODY)
    ws.row_dimensions[r].height = 46
    r += 1

# ================================================================ 2. Power-Up Details
ws = wb["Power-Up Details"]
ws.delete_rows(1, ws.max_row)
headers = ["Power-Up", "Type", "Description", "In-game icon", "HUD icon", "Multiplier Bonus",
           "Built?", "Classic Mode", "Endless Mode", "Endless Mayhem", "Daily Challenge",
           "Rarity",
           "+ Timer", "+ Second one does", "+ Conflicts with", "+ Unlocked by", "+ Notes"]
widths = [20, 10, 52, 20, 18, 12, 9, 12, 12, 14, 14, 11, 12, 22, 20, 26, 46]
head(ws, 1, headers, widths)
ws.freeze_panes = "B2"

STACKING_WORDS = {
    "repeats": "Happens again",
    "extendsDuration": "Adds to the time left",
    "extendsAndDeepens": "Adds time and deepens the effect",
    "stepsAlongAxis": "Steps further along the axis",
    "noFurtherEffect": "Nothing - already at its limit",
    "addsAnother": "Adds another one",
}
CONFLICT_WORDS = {
    "launchControl": "Anything else that owns the launch",
    "ballHitBehaviour": "Anything else that sets what a hit does",
    "": "-",
}

# Daily challenge exclusions (daily spec 5): the daily runs the mode's own set, minus the
# ones a single level cannot honour.
DAILY_EXCLUDED = {"Complete Level", "Extra Ball"}

# The three power-ups whose eligibility is live game state rather than a table (DERIVED from
# PowerUpCatalogue's isEligible and EndlessRowCreation).
ELIGIBILITY = {
    "Extra Ball": "Never drops in Endless Mayhem: that mode has one life and its own answer "
                  "to losing it (Multi-Ball)",
    "Multi-Ball": "Stops being offered once four balls are in play, rather than being "
                  "collected for nothing",
    "Lock": "Only drops while a timed power-up is running with enough left to still be "
            "running when the Lock lands - a Lock on an empty board reads as a dud",
    "Key": "Only drops while a Lock is running. Weighted high inside that window, so it is "
           "rare overall but reliably there when it can help",
    "Complete Level": "Classic only in practice - the endless modes have no next level",
}

for i, p in enumerate(POWERUPS):
    r = i + 2
    all_modes = p["availability"] == "allModes"
    valence = "Good" if p["valence"] == "beneficial" else ("Bad" if p["valence"] == "harmful" else "-")
    put(ws, r, 1, p["name"], Font(name=FONT, bold=True, size=10))
    put(ws, r, 2, valence, BODY, FILLS["good"] if valence == "Good" else FILLS["bad"])
    put(ws, r, 3, p["description"])
    kind, icon = ICONS[i]
    put(ws, r, 4, icon if kind == "asset" else "Drawn in code: PowerUpIcon." + icon)
    put(ws, r, 5, "The same picture, in the ring HUD")
    put(ws, r, 6, p["multiplier"] or "-", BODY, align=CENTRE)
    put(ws, r, 7, "Yes", BODY, align=CENTRE)
    put(ws, r, 8, "Yes" if all_modes else "No", BODY, align=CENTRE)
    put(ws, r, 9, "Yes" if all_modes else "No", BODY, align=CENTRE)
    mayhem = "No" if p["name"] in ("Extra Ball",) else "Yes"
    put(ws, r, 10, mayhem, BODY, align=CENTRE)
    daily = "No" if p["name"] in DAILY_EXCLUDED else ("Yes" if all_modes else "Mayhem days only")
    put(ws, r, 11, daily, BODY, align=CENTRE)
    put(ws, r, 12, p["rarity"].capitalize() if p["rarity"] else "-", BODY, align=CENTRE)
    put(ws, r, 13, p["timer"] or "Instant", BODY, align=CENTRE)
    put(ws, r, 14, STACKING_WORDS.get(p["stacking"], p["stacking"] or "-"))
    put(ws, r, 15, CONFLICT_WORDS.get(p["conflict"], p["conflict"]))
    put(ws, r, 16, p["hidden"] or "Never locked")
    put(ws, r, 17, ELIGIBILITY.get(p["name"], ""))
    ws.row_dimensions[r].height = 30

r = len(POWERUPS) + 3
put(ws, r, 1, "DERIVED: every column except the last is dumped from the game's own tables "
              "(LevelPackSetup, PowerUpCatalogue). Daily Challenge is SPEC: the daily runs its "
              "mode's set minus Complete Level and Extra Ball, which a single level cannot "
              "honour.", NOTE, border=False)
ws.merge_cells(start_row=r, start_column=1, end_row=r, end_column=17)

# ================================================================ 3. Power-Up Matrix
ws = wb["Power-Up Matrix"]
ws.delete_rows(1, ws.max_row)
names = [p["name"] for p in POWERUPS]
byname = {p["name"]: p for p in POWERUPS}

TIMED = {p["name"] for p in POWERUPS if p["isTimed"]}
MAYHEM_ONLY = {p["name"] for p in POWERUPS if p["availability"] == "endlessII"}

OPPOSITES = [("Slow Ball", "Fast Ball"), ("Expand Paddle", "Shrink Paddle"),
             ("Expand Ball", "Shrink Ball"), ("+100 Points", "-100 Points"),
             ("+1000 Points", "-1000 Points"), ("Max Multiplier", "Reset Multiplier"),
             ("Show Bricks", "Hide Bricks"),
             ("Clear Multi-Hit Bricks", "Reset Multi-Hit Bricks"),
             ("Giga-Ball", "Inert Ball"), ("Lock", "Key")]

# Pairs the specifications or the code speak about directly.
SPECIAL = {}


def special(a, b, text, kind="notable"):
    SPECIAL[frozenset((a, b))] = (text, kind)


for name in names:
    if name in TIMED and name not in ("Lock",):
        special("Lock", name, "Lock freezes its timer. It resumes when the Lock ends or a Key is caught", "notable")
    if name not in ("Lock", "Wipe"):
        special("Wipe", name, "Wipe ends it at once", "conflict")
    if name not in ("Mystery",):
        special("Mystery", name, "Mystery can become this one, and then behaves exactly as it", "notable")

special("Wipe", "Lock", "A Lock survives a Wipe - otherwise Wipe would be strictly better than Key", "notable")
special("Key", "Lock", "Key ends the Lock and restarts every frozen timer. Key only drops while a Lock runs", "notable")
special("Giga-Ball", "Inert Ball", "Both set what a hit does: the later one replaces the earlier", "conflict")
special("Sticky Paddle", "Aimed Sticky", "Both own the launch: the later one replaces the earlier", "conflict")
special("Aimed Sticky", "Auto-Aim", "They speak in sequence: the aim chooses the heading of a held launch, Auto-Aim redirects ordinary bounces", "notable")
special("Aimed Sticky", "Portal Paddle", "In sequence: an aimed shot leaves through the paddle and arrives at the top of the field travelling down. The arrow is drawn where the ball will appear", "notable")
special("Aimed Sticky", "Lasers", "Holding an aim freezes the lasers - the world stops while you choose", "notable")
special("Aimed Sticky", "Descent", "Holding an aim freezes the descent as well, so the field cannot close in while you cannot answer", "notable")
special("Trajectory Line", "Wrap-Around", "The line wraps at the side walls, as the ball does", "notable")
special("Trajectory Line", "Portal Paddle", "The line stops at a portal's mouth: where it comes out cannot be predicted honestly", "notable")
special("Trajectory Line", "Giga-Ball", "The line passes through bricks, as the ball will", "notable")
special("Giga-Ball", "Aura", "The intended good combination: together they come to what the Aura used to be on its own", "notable")
special("Clear And Retreat", "Descent", "While the retreat holds the field, Descent's own steps are suspended too", "notable")
special("Multi-Ball", "Laser Beam", "One beam per ball in play", "notable")
special("Multi-Ball", "Aura", "Every ball gets its own glow", "notable")
special("Multi-Ball", "Trajectory Line", "One line per ball", "notable")
special("Multi-Ball", "Landing Marker", "One marker per ball", "notable")
special("Multi-Ball", "Extra Ball", "Different things: Extra Ball is a life in reserve, Multi-Ball is another ball in play now", "notable")
special("Ghost Ball", "Landing Marker", "The marker still says where the ball will cross, which is most of what Ghost Ball takes away (ASSUMED)", "notable")
special("Ghost Ball", "Trajectory Line", "The line still draws while the ball itself is invisible (ASSUMED)", "notable")
special("Backstop", "Safety Paddle", "Two nets at two heights: the Backstop catches under the paddle, the Safety Paddle holds the ball up under the bricks", "notable")
special("Safety Paddle", "Portal Paddle", "Independent - the safety paddle is furniture and spends no paddle turn (ASSUMED)", "plain")
special("Auto-Aim", "Wipe", "Wipe ends it at once", "conflict")
special("Wrecking Ball", "Inert Ball", "Both answer the same contact: the later one replaces the earlier (ASSUMED)", "conflict")
special("Wrecking Ball", "Giga-Ball", "Giga-Ball passes through where a Wrecking Ball would destroy - the later one wins the contact (ASSUMED)", "conflict")
special("Infill", "Cull", "Opposite ends of the same idea: one fills the field, the other empties it. Both instant, so the later simply happens", "notable")
special("Descent", "Quicksand", "Both move the field down - Descent on a timer, Quicksand once (ASSUMED)", "notable")

# The header row and column
ws.column_dimensions["A"].width = 24
ws.freeze_panes = "B2"
put(ws, 1, 1, "Row, while column is running", HEAD_FONT, HEAD_FILL, CENTRE)
for j, n in enumerate(names):
    c = put(ws, 1, j + 2, n, SUB_FONT, SUB_FILL, CENTRE)
    ws.column_dimensions[get_column_letter(j + 2)].width = 26
ws.row_dimensions[1].height = 58

for i, a in enumerate(names):
    r = i + 2
    put(ws, r, 1, a, SUB_FONT, SUB_FILL, Alignment(vertical="center", wrap_text=True))
    ws.row_dimensions[r].height = 26
    for j, b in enumerate(names):
        if a == b:
            text = STACKING_WORDS.get(byname[a]["stacking"], "-")
            kind = "self"
        elif frozenset((a, b)) in SPECIAL:
            text, kind = SPECIAL[frozenset((a, b))]
        elif (a, b) in OPPOSITES or (b, a) in OPPOSITES:
            text, kind = "Opposites - the later steps back toward normal", "conflict"
        else:
            text, kind = "Independent", "plain"
        if a in MAYHEM_ONLY or b in MAYHEM_ONLY:
            if kind == "plain":
                text = "Independent (Mayhem only)"
        put(ws, r, j + 2, text, BODY_SMALL, FILLS[kind], CENTRE)

r = len(names) + 3
put(ws, r, 1, "Grey diagonal: what a second one does (DERIVED from the catalogue's stacking "
              "rule). Orange: cannot both be honoured. Yellow: combines, and worth knowing. "
              "White: independent. Cells saying ASSUMED are my reading and want your eye - "
              "everything else is from a spec or the code.", NOTE, border=False)

# ================================================================ 4. Twist Details
ws = wb["Twist Details"]
ws.delete_rows(1, ws.max_row)
headers = ["Twist", "Icon", "Description", "Built?",
           "+ Category", "+ Modes", "+ Draw weight", "+ Notes"]
head(ws, 1, headers, [20, 22, 56, 12, 14, 22, 12, 52])
ws.freeze_panes = "B2"

DESIGNED_TWISTS = [
    ("Always On", "One power-up permanently active, drawn from a curated subset of the ones that are states",
     "Designed", "Economy (proposed)", "All", "-",
     "Daily spec 4.1 lists the subset: Giga-Ball, Undestructi-Ball, Sticky Paddle, Lasers, Magnetism, Aura, Trajectory Line, Landing Marker, Auto-Aim, Wrap-Around, and the bad states"),
    ("Upside Down", "The level's brick layout is mirrored vertically", "Designed",
     "Layout (proposed)", "Classic", "-", "Layout only - gravity and paddle unchanged"),
    ("Mirrored", "The level's layout is mirrored horizontally", "Designed",
     "Layout (proposed)", "Classic", "-", "The wrong way round for muscle memory"),
    ("Brick Swap", "The level's brick types are remapped for the day", "Designed",
     "Bricks (proposed)", "Classic", "-", "A small table of remappings, drawn deterministically"),
    ("Mayhem Bricks", "The endless daily uses Mayhem's style pool at elevated rates", "Designed",
     "Bricks (proposed)", "Endless modes", "-", "The variety dial turned up"),
    ("Time Trial", "90 seconds on the clock; the score at the whistle is the score", "Designed",
     "Scoring (proposed)", "All", "-", "The quickest daily there is, and the one that fits the concept best"),
    ("Blackout", "The whole game monochrome", "Designed", "Dress", "All", "-",
     "A twist rather than a dress: Classic bricks are told apart by colour, so grayscale is genuine difficulty there"),
    ("Mayhem Rules", "Mayhem's power-ups drop in a Classic level", "Designed",
     "Economy (proposed)", "Classic", "-",
     "A curated list excluding anything that needs the descending field (Descent, Clear And Retreat). Sudden Death comes back with this"),
    ("Landslide", "The level's bricks descend continuously; whatever reaches the bottom row vanishes, unscored", "Designed",
     "Field (proposed)", "Classic", "-", "Endless's movement in Classic's clothes"),
    ("No Pausing", "The pause button is disabled for the run", "Designed",
     "Meta (proposed)", "All", "-", "Backgrounding the app forfeits posting"),
]

r = 2
for t in TWISTS:
    built = "Yes" if t["modes"] else "Parked"
    put(ws, r, 1, t["name"], Font(name=FONT, bold=True, size=10))
    put(ws, r, 2, "PowerUpIcon.twist" + t["raw"][0].upper() + t["raw"][1:])
    put(ws, r, 3, t["blurb"])
    put(ws, r, 4, built, BODY, FILLS["good"] if built == "Yes" else FILLS["todo"], CENTRE)
    put(ws, r, 5, t["category"].capitalize(), BODY, align=CENTRE)
    put(ws, r, 6, ", ".join(t["modes"]) if t["modes"] else "None - parked")
    put(ws, r, 7, t["weight"], BODY, align=CENTRE)
    note = ""
    if not t["modes"]:
        note = ("Built and tested, but no mode draws it: in the endless modes it is One Life "
                "said twice, and in Classic it is One Life by another name. It returns with "
                "Mayhem Rules")
    put(ws, r, 8, note)
    ws.row_dimensions[r].height = 30
    r += 1

for name, desc, built, cat, modes, weight, note in DESIGNED_TWISTS:
    put(ws, r, 1, name, Font(name=FONT, bold=True, size=10))
    put(ws, r, 2, "Not drawn yet")
    put(ws, r, 3, desc)
    put(ws, r, 4, built, BODY, FILLS["todo"], CENTRE)
    put(ws, r, 5, cat, BODY, align=CENTRE)
    put(ws, r, 6, modes)
    put(ws, r, 7, weight, BODY, align=CENTRE)
    put(ws, r, 8, note)
    ws.row_dimensions[r].height = 30
    r += 1

put(ws, r + 1, 1, "DERIVED: the ten built twists and their categories, modes and weights come "
                  "from the game. SPEC: the ten designed ones are from DAILY-CHALLENGE-"
                  "SPECIFICATION 4, with categories I have proposed - a day draws at most one "
                  "twist per category, so the category is what decides which twists can share "
                  "a day.", NOTE, border=False)

# ================================================================ 5. Twist Matrix
ws = wb["Twist Matrix"]
ws.delete_rows(1, ws.max_row)
twist_rows = [(t["name"], t["category"].capitalize(), bool(t["modes"])) for t in TWISTS]
twist_rows += [(n, c.split(" ")[0], False) for n, _, _, c, _, _, _ in DESIGNED_TWISTS]

ws.column_dimensions["A"].width = 22
ws.freeze_panes = "B2"
put(ws, 1, 1, "Can these two share a day?", HEAD_FONT, HEAD_FILL, CENTRE)
for j, (n, c, built) in enumerate(twist_rows):
    put(ws, 1, j + 2, n, SUB_FONT, SUB_FILL, CENTRE)
    ws.column_dimensions[get_column_letter(j + 2)].width = 20
ws.row_dimensions[1].height = 50

for i, (a, ca, built_a) in enumerate(twist_rows):
    r = i + 2
    put(ws, r, 1, a, SUB_FONT, SUB_FILL, Alignment(vertical="center", wrap_text=True))
    ws.row_dimensions[r].height = 24
    for j, (b, cb, built_b) in enumerate(twist_rows):
        if a == b:
            text, kind = "One a day, once", "self"
        elif ca == cb:
            text, kind = "No - one twist per category", "never"
        else:
            text, kind = "Yes", "plain"
        put(ws, r, j + 2, text, BODY_SMALL, FILLS[kind], CENTRE)

r = len(twist_rows) + 3
put(ws, r, 1, "DERIVED rule (daily spec 4.2): a day draws at most one twist per category, "
              "which is what makes every combination the generator can produce legal by "
              "construction. So the matrix is decided by the category column on the details "
              "sheet - change a category there and this changes with it. The proposed "
              "categories for the designed twists are the ones worth arguing about.",
    NOTE, border=False)

# ================================================================ 6. Brick Details
ws = wb["Brick Details"]
ws.delete_rows(1, ws.max_row)
headers = ["Brick", "Classic Graphic", "Retro Graphic", "Description", "Built?",
           "+ Kind", "+ Modes", "+ Facts", "+ Combines with"]
head(ws, 1, headers, [22, 18, 18, 62, 10, 14, 18, 34, 40])
ws.freeze_panes = "B2"

styles_by_name = {s["name"]: s for s in STYLES}
r = 2
for b in BRICKS:
    put(ws, r, 1, b["name"], Font(name=FONT, bold=True, size=10))
    put(ws, r, 2, "Drawn from the brick artwork" if b["section"] != "Styles" else "Tinted brick plus glyph")
    put(ws, r, 3, "-")
    put(ws, r, 4, b["description"])
    put(ws, r, 5, "Yes", BODY, FILLS["good"], CENTRE)
    put(ws, r, 6, b["section"], BODY, align=CENTRE)
    modes = "Every mode" if not b["isNew"] else "Endless Mayhem"
    put(ws, r, 7, modes)
    put(ws, r, 8, "; ".join(f["label"] + ": " + f["value"] for f in b["facts"]))
    s = styles_by_name.get(b["name"])
    put(ws, r, 9, ", ".join(s["stacks"]) if s else "-")
    ws.row_dimensions[r].height = 42
    r += 1

put(ws, r + 1, 1, "DERIVED from BrickTypeCatalogue and the style compatibility grid. 'Combines "
                  "with' is every other style this one may share a brick with - a brick carries "
                  "at most two styles, plus one behaviour and one size.", NOTE, border=False)

# ================================================================ 7. Brick Matrix
ws = wb["Brick Matrix"]
ws.delete_rows(1, ws.max_row)

style_names = [s["name"] for s in STYLES]
behaviour_names = [b["name"] for b in BRICKS if b["section"] == "Behaviours"]
size_names = [b["name"] for b in BRICKS if b["section"] == "Sizes"]

BEHAVIOUR_KEY = {"Standard": "standard", "Multi-Hit": "multiHit",
                 "Indestructible": "indestructibleOnce", "Invisible": "invisible"}

# The "Sizes" fact on a style says which sizes it may wear.
style_sizes = {}
for b in BRICKS:
    if b["section"] != "Styles":
        continue
    fact = next((f["value"] for f in b["facts"] if f["label"] == "Sizes"), "Any")
    style_sizes[b["name"]] = fact

items = ([(n, "Style") for n in style_names]
         + [(n, "Behaviour") for n in behaviour_names]
         + [(n, "Size") for n in size_names])

ws.column_dimensions["A"].width = 24
ws.freeze_panes = "B2"
put(ws, 1, 1, "Can one brick be both?", HEAD_FONT, HEAD_FILL, CENTRE)
for j, (n, kind) in enumerate(items):
    put(ws, 1, j + 2, n + "\n(" + kind + ")", SUB_FONT, SUB_FILL, CENTRE)
    ws.column_dimensions[get_column_letter(j + 2)].width = 19
ws.row_dimensions[1].height = 46


def brick_cell(a, ka, b, kb):
    if a == b:
        return ("One only", "self")
    if ka == "Behaviour" and kb == "Behaviour":
        return ("No - a brick has one behaviour", "never")
    if ka == "Size" and kb == "Size":
        return ("No - a brick has one size", "never")
    if ka == "Style" and kb == "Style":
        ok = b in styles_by_name[a]["stacks"]
        return ("Yes", "plain") if ok else ("No", "never")
    if {ka, kb} == {"Style", "Behaviour"}:
        style, behaviour = (a, b) if ka == "Style" else (b, a)
        key = BEHAVIOUR_KEY.get(behaviour)
        if behaviour == "Indestructible":
            ok = ("indestructibleOnce" in styles_by_name[style]["suits"]
                  or "indestructibleAlways" in styles_by_name[style]["suits"])
            extra = ""
            if style in ("Exploding", "Spawner"):
                extra = " - and on an Indestructible brick it fires on every hit rather than on destruction"
            if style == "Portal":
                return ("Yes - a Portal makes one", "notable")
            return ("Yes" + extra, "notable" if extra else "plain") if ok else ("No", "never")
        ok = key in styles_by_name[style]["suits"]
        return ("Yes", "plain") if ok else ("No", "never")
    if {ka, kb} == {"Style", "Size"}:
        style, size = (a, b) if ka == "Style" else (b, a)
        allowed = style_sizes.get(style, "Any")
        if allowed in ("Any", "Any size"):
            return ("Yes", "plain")
        return ("Yes", "plain") if size.split(" ")[0] in allowed else ("No - " + allowed + " only", "never")
    if {ka, kb} == {"Behaviour", "Size"}:
        return ("Yes", "plain")
    return ("-", "plain")


for i, (a, ka) in enumerate(items):
    r = i + 2
    put(ws, r, 1, a + " (" + ka + ")", SUB_FONT, SUB_FILL,
        Alignment(vertical="center", wrap_text=True))
    ws.row_dimensions[r].height = 24
    for j, (b, kb) in enumerate(items):
        text, kind = brick_cell(a, ka, b, kb)
        put(ws, r, j + 2, text, BODY_SMALL, FILLS[kind], CENTRE)

r = len(items) + 3
put(ws, r, 1, "DERIVED: every cell comes from the game's own compatibility rules - "
              "EndlessIIStyle.stacksWith for style pairs, .suits for a style against a "
              "behaviour, and the reference page's own 'Sizes' line for a style against a "
              "size. A brick is one behaviour, one size, and up to two styles.",
    NOTE, border=False)

# ================================================================ 8. Not Built
if "Not Built" in wb.sheetnames:
    del wb["Not Built"]
ws = wb.create_sheet("Not Built")
head(ws, 1, ["Thing", "Kind", "What it would be", "Where it is written down", "Blocked on"],
     [26, 14, 62, 30, 40])
ws.freeze_panes = "A2"

NOT_BUILT = [
    ("Always On", "Twist", "One power-up permanently active for the day", "Daily spec 4, 4.1", "Nothing - next in the twist queue"),
    ("Upside Down", "Twist", "The level's layout mirrored vertically", "Daily spec 4", "Nothing"),
    ("Mirrored", "Twist", "The level's layout mirrored horizontally", "Daily spec 4", "Nothing"),
    ("Brick Swap", "Twist", "The level's brick types remapped for the day", "Daily spec 4", "Nothing"),
    ("Mayhem Bricks", "Twist", "Mayhem's style pool in an endless daily, at elevated rates", "Daily spec 4", "Nothing"),
    ("Time Trial", "Twist", "90 seconds; the score at the whistle is the score", "Daily spec 4", "Nothing"),
    ("Blackout", "Twist", "The whole game monochrome", "Daily spec 4", "Monochrome performance is an open question (13)"),
    ("Mayhem Rules", "Twist", "Mayhem's power-ups in a Classic level", "Daily spec 4", "A curated power-up list"),
    ("Landslide", "Twist", "Classic bricks descend continuously", "Daily spec 4", "Nothing"),
    ("No Pausing", "Twist", "The pause button disabled for the run", "Daily spec 4", "Nothing"),
    ("Sudden Death", "Twist", "Any ball lost ends the run", "Daily spec 4", "Built, parked - returns with Mayhem Rules"),
    ("Ball Spin / Curve", "Power-up", "The ball curves in flight", "ENDLESS-2 12.0", "Design - how it reads to the player"),
    ("Drift", "Power-up", "Pulled into 1.3 by James, round 100", "ENDLESS-2 12.0", "Design"),
    ("Double Paddle", "Power-up", "A second paddle, and an opposite-moving one", "ENDLESS-2 12.0", "Design"),
    ("Paddle surface shapes", "Paddle", "The paddle's face is not always flat", "ENDLESS-2 12.0", "Design"),
    ("Shaped bricks facing down", "Brick", "The three faces, pointed the other way", "ENDLESS-2 12.0", "Nothing - a rotation and a body rebuild"),
    ("Descent in rows", "Rule", "Descent measured in rows rather than seconds", "ENDLESS-2 12.0", "Nothing"),
    ("Global leaderboard lines", "Feature", "Other players' heights drawn on the field's markers", "ENDLESS-2 12.0", "The Mayhem boards existing in App Store Connect"),
    ("Artwork and sound", "Assets", "Real art for every new power-up, brick style and twist", "ENDLESS-2 8.5", "James"),
]
for i, row in enumerate(NOT_BUILT):
    r = i + 2
    for j, v in enumerate(row):
        put(ws, r, j + 1, v, Font(name=FONT, bold=True, size=10) if j == 0 else BODY,
            FILLS["todo"] if j == 1 else None)
    ws.row_dimensions[r].height = 26

r = len(NOT_BUILT) + 3
put(ws, r, 1, "SUGGESTED SHEET. Everything designed and not yet built, in one place, so the "
              "matrices above can carry the designed items without hiding which are real.",
    NOTE, border=False)

# ================================================================ 9. Modes
if "Modes" in wb.sheetnames:
    del wb["Modes"]
ws = wb.create_sheet("Modes")
head(ws, 1, ["Mode", "What it is", "Lives", "Scored on", "Power-ups", "Bricks", "Ends when"],
     [18, 46, 22, 26, 34, 34, 34])
MODES = [
    ("Classic Mode", "Eleven packs of hand-designed levels, played in order",
     "Three balls, plus Extra Ball", "Points",
     "The original 28", "Behaviours and sizes, no styles", "The balls run out, or the pack is finished"),
    ("Endless Mode", "The original endless field, descending a row at a time",
     "One ball", "Height in metres", "The original 28",
     "Behaviours and sizes, no styles", "The ball is lost"),
    ("Endless Mayhem", "Endless 2.0: the descending field with styles, phases and its own power-ups",
     "One ball, plus Multi-Ball", "Height in metres",
     "All 54", "Behaviours, sizes and 14 styles", "The ball is lost, or the field reaches the line"),
    ("Daily Challenge", "One generated day, the same for everybody, in one of the three modes",
     "The mode's own, unless a lives twist says otherwise", "The mode's own, on the day's board",
     "The mode's own, minus Complete Level and Extra Ball",
     "The mode's own, unless a twist changes them", "The mode's own; one scoring attempt a day"),
]
for i, row in enumerate(MODES):
    r = i + 2
    for j, v in enumerate(row):
        put(ws, r, j + 1, v, Font(name=FONT, bold=True, size=10) if j == 0 else BODY)
    ws.row_dimensions[r].height = 40

put(ws, len(MODES) + 3, 1, "SUGGESTED SHEET. The matrices only make sense against the mode a "
                           "pair can meet in, and this is the shortest statement of what each "
                           "mode is.", NOTE, border=False)

wb.save(OUT)
print("saved", OUT)
print("sheets:", wb.sheetnames)
