---
name: file-sync
description: Syncs binary documents (PDF, PPT, PPTX, DOCX, XLSX, XLSM) into Markdown for AI reading, and converts Markdown back to Word (.docx) or PDF. Installs project-local sync scripts, VS Code tasks, and Cursor rules. Handles OCR for scanned PDFs, PDF broken-line joining, per-sheet Markdown for Excel, legacy .ppt conversion on Windows, and final delivery-quality audit. Use when the user mentions PDF, PPT, PPTX, DOCX, XLSX, XLSM, Excel, spreadsheets, presentations, scanned documents, or asks to export Markdown as Word/DOCX/PDF. Post-extraction readability cleanup (encoding residuals, rich-text artifacts, structural rewrites) is delegated to the `md-cleanup` skill.
---

# File Sync

Unified skill for binary-document ↔ Markdown conversion and extraction-specific post-processing. Three parts:

- **Binary → MD**: Sync PDF/PPT/PPTX/DOCX/XLSX/XLSM into readable Markdown
- **MD → DOCX / PDF**: Convert Markdown files to formatted Word documents or PDF files
- **Extraction-specific post-processing**: Empty-file OCR re-extraction, PDF broken-line joining, final delivery-quality audit

Generic MD readability cleanup (character-level residuals, rich-text export artifacts, structural rewrites) is **not** done here — it's delegated to the sibling `md-cleanup` skill and invoked automatically at the right step.

---

## ⚠️ 交付前硬约束（Delivery Hard Constraint）

**任何** binary → MD 转换，无论是用 `tools/file_sync.py` 正式管线、还是临时写的一次性内联脚本，交付给用户前**必须**跑完以下顺序，一步不能跳：

1. **Step 0**：空页 / 图片页 OCR 重抽（Part C）
2. **md-cleanup 脚本段**：调 `md-cleanup` skill 的 `scripts/md_cleanup.py` 跑 F1 / F2 / F3 / F4 / F6 家族（agent MUST read `~/.cursor/skills/md-cleanup/SKILL.md`）
3. **Step 1.5**：断行合并 `md_line_join.py`（PDF 类来源必做；Part C）
4. **md-cleanup AI 段**：按 `md-cleanup/SKILL.md` 的 F5 规则做结构级语义重排（命中触发条件时必做）
5. **Step 3**：最终验证审计（Part C）

**只做 Step 0 就交付 = 流程违规。** 用户不需要提醒 "可读性高一点"，md-cleanup AI 段由 F5 触发条件决定，不是由用户提醒决定。

内联脚本不是绕过这 5 步的借口——脚本只负责"怎么抽"，后续 5 步一条不能少。

**扫读友好度硬指标**：交付前必做一次计算——`MD 行数 ÷ Excel 数据行数 ≤ 3`。比值 ≥ 3 = 抽取格式错（十有八九是 X1 竖排 key-value），必须回去改为表格格式，不得交付。见 `md-cleanup/SKILL.md` 的"交付前扫读友好度自检"。

## When To Use

- User asks to read, summarize, or analyze a PDF, PPT, PPTX, DOCX, XLSX, or XLSM file
- User drops a new binary document into the project
- User wants the sync workflow installed into a new project
- User asks to export/convert Markdown to Word (.docx) or PDF (.pdf)
- OCR output needs cleaning (scanned PDFs)

For generic MD readability cleanup (encoding residuals, Dingtalk/Feishu/Notion export artifacts, heading hierarchy rewrites), the `md-cleanup` skill handles it.

---

## Part A: Binary → Markdown Sync

### Reading Synced Files (project already has sync installed)

1. Read `cursor_sync/index.md` (or `cursor_docs/index.md` / `cursor_excel/index.md`) first.
2. For scanned PDFs, prefer `cleaned.md` if it exists.
3. For Excel, read the per-sheet `.md` files under the workbook's output folder.
4. For DOCX/PPTX, read `document.md`.
5. If artifacts are missing or stale, run `python "tools/file_sync.py"` from the project root.

### Output Format

| Format | Output |
|--------|--------|
| PDF | `document.md` + optional `cleaned.md` (OCR) |
| PPT/PPTX | `document.md` (per-slide) |
| DOCX | `document.md` |
| XLSX/XLSM | One `.md` per sheet |

### Installing Sync Into a New Project

1. **Inspect** the target project for:
   - Existing binary files (`.pdf`, `.pptx`, `.ppt`, `.xlsx`, `.xlsm`, `.docx`)
   - Existing `.cursor`, `.vscode`, or `tools` folders
   - Existing `tasks.json` or rules that must be preserved
   - Python availability and required packages

2. **Check dependencies**:
   - Documents: `pypdf`, `python-pptx` (required)
   - Excel: `openpyxl`
   - OCR (REQUIRED for scanned/image PDFs and image-based PPTX): `pymupdf`, `pytesseract`, `Pillow`, plus **Tesseract OCR binary** — see [OCR Setup](#ocr-setup) below
   - If missing, ask user before installing

3. **Install project files** using templates from this skill:

   **For documents** (PDF/PPT/PPTX/DOCX):
   - `tools/document_sync.py` ← from `templates/document/template_document_sync.py`
   - `tools/watch_documents.py` ← from `templates/document/template_watch_documents.py`
   - `tools/convert_legacy_ppt.ps1` ← from `templates/document/template_convert_legacy_ppt.ps1`
   - `document_sync_config.json` ← from `templates/document/template_config.json`
   - `.cursor/rules/document-sync.mdc` ← from `templates/document/template_rule.mdc`

   **For Excel** (XLSX/XLSM):
   - `tools/excel_sync.py` ← from `templates/excel/template_excel_sync.py`
   - `tools/watch_excel.py` ← from `templates/excel/template_watch_excel.py`
   - `excel_sync_config.json` ← from `templates/excel/template_config.json`
   - `.cursor/rules/excel-sync.mdc` ← from `templates/excel/template_rule.mdc`

   **Shared**:
   - `.vscode/tasks.json` — merge all task labels (see reference)
   - `FILE_SYNC_README.md`

4. **Merge rules**: If `.vscode/tasks.json` or `.cursor/rules/` already exist, merge carefully — preserve unrelated tasks/rules.

5. **Run sync**: `python "tools/document_sync.py"` and/or `python "tools/excel_sync.py"`

6. **Verify**: Check that `index.md` was generated; summarize what was tracked.

7. **→ 进入交付前 5 步处理链，不得直接交付。** Part A 产出的是"抽出来的原始 MD"，不是"可交付的 MD"。处理链：Step 0（本文 Part C） → md-cleanup 脚本段 → Step 1.5（本文 Part C） → md-cleanup AI 段 → Step 3（本文 Part C）。参见文档顶部"交付前硬约束"。

### Operating Rules

- Project-local installation only. Do not write sync outputs into the skill directory.
- Only output `.md` files. No `.csv`, `.json`, or manifest files.
- Exclude temporary lock files (`~$*.xlsx`).
- For legacy `.ppt`: use PowerShell converter on Windows; report if PowerPoint is missing.
- For PDFs: direct text extraction first; **if a page returns empty or junk (< 5 real chars), MUST OCR that page** — never leave it as `[No text extracted]`.
- For PPTX: if a slide has Picture shapes but no/little text, **MUST OCR the embedded images**.
- Default OCR languages: `eng` (add `chi_sim` if Chinese content expected).
- Respect existing user changes in project files.

### OCR Setup

OCR is **NOT optional** — many real-world PDFs and PPTX files are image-based. Set up OCR **before** running any extraction.

#### 1. Detect Tesseract

Run this check at the start of any extraction task:

```python
import shutil, os

tesseract_path = shutil.which("tesseract")
if not tesseract_path:
    # Windows common locations
    for candidate in [
        r"C:\Program Files\Tesseract-OCR\tesseract.exe",
        r"C:\Program Files (x86)\Tesseract-OCR\tesseract.exe",
        os.path.expandvars(r"%LOCALAPPDATA%\Programs\Tesseract-OCR\tesseract.exe"),
    ]:
        if os.path.isfile(candidate):
            os.environ["PATH"] = os.path.dirname(candidate) + os.pathsep + os.environ["PATH"]
            tesseract_path = candidate
            break

if not tesseract_path:
    # Install: winget install UB-Mannheim.TesseractOCR
    raise RuntimeError("Tesseract not found — install it or add to PATH")
```

#### 2. Python packages

```bash
pip install pymupdf pytesseract Pillow
```

#### 3. Image size guard

Tesseract crashes on images > ~30 megapixels. **Always scale down** before OCR:

```python
from PIL import Image
Image.MAX_IMAGE_PIXELS = None  # disable decompression bomb check

def safe_ocr_page(page, lang="eng"):
    """Render a pymupdf page to image and OCR, with automatic downscaling."""
    import fitz, pytesseract
    scale = 1.5
    pix = page.get_pixmap(matrix=fitz.Matrix(scale, scale), alpha=False)
    while max(pix.width, pix.height) > 4000:
        scale *= 0.7
        pix = page.get_pixmap(matrix=fitz.Matrix(scale, scale), alpha=False)
    img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
    return pytesseract.image_to_string(img, lang=lang).strip()
```

#### Key Principle

**Never deliver a file with `[No text extracted]` or empty content without first attempting OCR.** If OCR also fails, write `[OCR attempted — no text recognized]` so the user knows it was tried.

### Configuration

Edit `file_sync_config.json` / `document_sync_config.json` / `excel_sync_config.json` to add custom noise patterns, stop markers, or exclude patterns.

### Excel 专项规则（避免 md-cleanup 反复手修）

Excel 抽取天然有四个陷阱，每一个都会让下游 md-cleanup 被迫做 F5.5 手工重排。抽取端就该修好：

| # | 陷阱 | 正确做法 |
|---|---|---|
| X1 | **默认输出成竖排 key-value**（每行数据 → 一个 `### 第 N 行` + 一堆 `- 字段: 值`），37 行数据膨胀到 290 行 MD | 每张 sheet 输出**一个 Markdown 表格**：字段做列头，一行数据 = 表格一行。空单元格留空即可 |
| X2 | **合并单元格没展开**（openpyxl 对合并区的非左上角单元格返回 `None`），"平台"列只在每组首行有值、下面一串空 | 遍历 `ws.merged_cells.ranges`，把左上角值填到整个合并区的每个格子 |
| X3 | **表头检测被合并横幅顶掉**（row 1 是 `@某某 @备注` 合并成一整行，展开后非空数超过真表头所在 row，得分反超） | 策略改为"**自上而下遍历，首个满足 ≥2 非空 + 唯一度（unique / total） ≥ 0.7 的行即表头**"。合并整行横幅唯一度 = 1/N 必定跳过；普通表头即便有 1–2 个重复列名（如主 KPI + 次 KPI）也能通过 |
| X4 | **表头单元格含真实 `\n`**（"受众人群\nINT:xx\nRMKT:yy"）直接拼进 `\| ... \|` 把表格撑坏 | 表头也过 `cell_md()`：`\r\n` / `\n` → `<br>`，`\|` → `\\|` |

附加优化：**空占位列剪枝**——列名是 `column_N`（make_headers 给无表头列生成的默认名）且该列数据全空，可安全删除，让表格更窄。

这四条只要抽取端一次到位，md-cleanup 就不用每次都 F5.5 手修。参考实现参见 `md-cleanup/references/artifact-patterns.md` 的 "Excel 抽取" 节 E1–E5。

---

## Part B: Markdown → DOCX / PDF

### Prerequisites

- Python 3.8+
- `python-docx` (for DOCX, ask user before installing if missing)
- `markdown-pdf` (for PDF, ask user before installing if missing)

### Conversion Workflow

1. Identify the source `.md` file from user's request.
2. Output path: default same directory, same name with `.docx` or `.pdf` extension.
3. Run:

**For DOCX:**
```bash
python "<skill-dir>/scripts/md_to_docx.py" "<input.md>" "<output.docx>"
```

**For PDF:**
```bash
python "<skill-dir>/scripts/md_to_pdf.py" "<input.md>" "<output.pdf>"
```

Replace `<skill-dir>` with the absolute path to this skill directory.

4. Verify output file exists and report its size and path.

### Supported Elements

| Markdown | DOCX Output | PDF Output |
|---|---|---|
| `# H1` – `#### H4` | Heading levels 1–4 | Headings + Bookmarks |
| `**bold**`, `*italic*`, `` `code` `` | Inline formatting | Inline formatting |
| `> blockquote` | Left-bordered indented paragraph | Blockquotes |
| `- item` / `* item` | Bullet list | Bullet list |
| Pipe tables | Styled table with dark header row | Standard tables |
| `<br>` in table cells | Line breaks within cells | Line breaks |

### Customization

- **DOCX**: Edit constants at top of `scripts/md_to_docx.py`: `FONT_BODY`, `FONT_CJK` (default: Microsoft YaHei), `FONT_CODE`, `FONT_SIZE_BODY`, page margins (default: 2.54 cm).
- **PDF**: Edit `scripts/md_to_pdf.py` to change table of contents levels, margins, etc. via the `markdown-pdf` API.

### Limitations

- Does not render images (`![](...)` kept as text)
- No nested lists deeper than one level
- Fenced code blocks rendered as monospace paragraphs, not syntax-highlighted

---

## Part C: Extraction-Specific Post-Processing

After binary-to-MD extraction (Part A), three things are still needed before delivery. **All of them are extraction-specific** and stay in `file-sync`:

- **Step 0** — Empty / image-only files need OCR re-extraction
- **Step 1.5** — PDF-extracted paragraphs have broken lines that need joining
- **Step 3** — Final delivery-quality audit

Between Step 0 and Step 1.5, **agent MUST invoke the `md-cleanup` skill's script segment** (F1 / F2 / F3 / F4 / F6). Between Step 1.5 and Step 3, **agent MUST invoke the `md-cleanup` skill's AI segment** if its F5 triggers are hit. See `~/.cursor/skills/md-cleanup/SKILL.md` for the full rule set.

```
Part A 抽取
   │
   ▼
[Step 0]  空页 / 图片页 OCR 重抽          (file-sync 本地)
   │
   ▼
[md-cleanup 脚本段]  F1/F2/F3/F4/F6 清洗    (md-cleanup skill)
   │
   ▼
[Step 1.5]  PDF 断行合并                  (file-sync 本地，PDF 来源必做)
   │
   ▼
[md-cleanup AI 段]   F5 结构级语义重排     (md-cleanup skill，命中 F5 触发条件时必做)
   │
   ▼
[Step 3]   最终验证审计                   (file-sync 本地)
   │
   ▼
交付用户
```

**Every step is mandatory — do not skip any, and do not wait for user to remind you.**

### Step 0: Empty File Audit & OCR Re-extraction

Immediately after Part A extraction completes, **scan ALL output `.md` files** and flag any that are empty or broken:

```python
for each .md file:
    content = read file, strip blank lines and the "# title" line
    if content is empty, or all lines are "[No text extracted]",
       or content is only junk chars (±, °, single symbols):
        → MUST re-extract with OCR (see OCR Setup in Part A above)
```

| Symptom | Cause | Action |
|---------|-------|--------|
| `[No text extracted]` on every page | Scanned / image-based PDF | `safe_ocr_page()` on each page |
| Only `±` `°` junk chars | PDF with symbol fonts, no real text | `safe_ocr_page()` on each page |
| PPTX slide has Picture shape but ≤1 line text | Content is in embedded images | Extract `shape.image.blob` → `pytesseract.image_to_string()` |
| Completely blank after OCR attempt | Corrupted or DRM-protected source | Write `[OCR attempted — no text recognized]`, report to user |

**This step is NOT optional.** Never deliver empty files to the user. Always attempt OCR before reporting failure.

After fixing empty files, **invoke md-cleanup skill's script segment** (see `~/.cursor/skills/md-cleanup/SKILL.md`) before continuing to Step 1.5.

```bash
python "~/.cursor/skills/md-cleanup/scripts/md_cleanup.py" <extracted.md files> --in-place
```

This handles character-level residuals (Kangxi radicals, NFKC, trad residuals), rich-text export artifacts, MD escape residuals, and blank-line noise. See md-cleanup/SKILL.md for the full rule matrix (F1–F6).

### Step 1.5: Broken Line Joining

PDF text extraction breaks sentences at the original column width, producing many short lines that should be continuous paragraphs. Run:

```bash
python "<skill-dir>/scripts/md_line_join.py" "<input.md>" --in-place
```

For batch processing:

```bash
python "<skill-dir>/scripts/md_line_join.py" *.md --in-place
```

This fixes:

| Problem | Example | Fix |
|---------|---------|-----|
| Mid-sentence line breaks | `bone conduction \ntechnology` | `bone conduction technology` |
| Hyphenated word breaks | `com-\nplete` | `complete` |
| Comma-split continuations | `with Bluetooth,\nplus USB-C` | `with Bluetooth, plus USB-C` |

**Preserved (not joined):**
- Headings (`#`), bullet lists (`- `), tables (`\|`), blank lines
- Known spec parameter names (e.g. `Part number`, `Frequency response`)
- Section headers (e.g. `SPECIFICATIONS`, `WHAT'S IN THE BOX`)

#### Detection — when to run

A file needs line joining when it matches ANY of:
- Contains 5+ lines shorter than 60 characters that end with a space or without sentence-ending punctuation
- PDF-extracted text where paragraphs are visibly broken across multiple short lines
- User complains about "断句" / "broken lines" / readability issues

**Always run after md-cleanup's script segment and before md-cleanup's AI segment.**

### → Invoke md-cleanup skill's AI segment

After Step 1.5, agent **MUST read** `~/.cursor/skills/md-cleanup/SKILL.md` and execute its F5 (structural / semantic) rules if any of these triggers are hit on any output file:

- 3+ `## Page \d+` or `## Slide \d+:` headings (F5.2, most common for file-sync output)
- All-flat `- ` bullets with no hierarchy (F5.3, flat PPTX extraction)
- Flat all-`#` heading hierarchy without `##` or deeper (F5.1)
- Empty section titles (F5.4)

Hitting any trigger = MUST run F5. Not a single trigger hit = skip straight to Step 3.

The specific restructuring rules (semantic headings, table reconstruction, bullet hierarchy, etc.) and the "NEVER fabricate content" guardrail all live in md-cleanup's SKILL.md now. Do not duplicate them here.

### Step 3: Final Validation Audit

After all 5 processing steps (Step 0 → md-cleanup script → Step 1.5 → md-cleanup AI → here), **scan every output file** and verify it passes ALL checks. This is the last gate before delivering to the user.

```python
for each .md file:
    text = read file
    content_lines = [non-blank, non-heading lines]

    # CHECK 1: Empty — content ≤ 2 lines
    # CHECK 2: No text — ≥50% lines are "[No text extracted]"
    # CHECK 3: Junk — strip ±°#-|spaces, if < 10 real chars left
    # CHECK 4: Raw headings — 3+ "## Page \d+" or "## Slide \d+:"
    # CHECK 5: OCR garbage — single-char lines like "£", "a", "Ol", "AAS"
    #           (3+ single-char or nonsense lines in a row = OCR junk)

    if ANY check fails → flag file, attempt auto-fix, re-check
```

#### Auto-fix actions by check type

| Failed check | Auto-fix action |
|---|---|
| EMPTY | Re-extract with OCR (Step 0) |
| NO_TEXT | Re-extract with OCR (Step 0) |
| JUNK | Re-extract with OCR (Step 0) |
| RAW_HEADINGS | Re-invoke md-cleanup AI segment (F5.2 semantic heading rewrite) |
| OCR_GARBAGE | Manually clean: remove single-char junk lines, reconstruct garbled feature lists from context, rebuild spec tables from readable OCR data |

#### Reporting

After the audit, print a summary:

```
Total: 65 files
  OK: 63
  Fixed: 2 (re-OCR'd)
  Remaining issues: 0

All files PASSED — ready for use.
```

**If any file still fails after auto-fix**, report it to the user with the specific issue, rather than silently delivering broken content.

#### When to run

- **Always** after completing Steps 0–2 on a batch
- **Always** before telling the user "conversion is done"
- When the user asks to "check" / "verify" / "检查" output quality

---

## Additional Reference

- For document sync templates and merge guidance, see [templates/document/reference.md](templates/document/reference.md)
- For Excel sync templates and merge guidance, see [templates/excel/reference.md](templates/excel/reference.md)
