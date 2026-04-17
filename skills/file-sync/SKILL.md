---
name: file-sync
description: Syncs binary documents (PDF, PPT, PPTX, DOCX, XLSX, XLSM) into Markdown for AI reading, cleans up extraction artifacts (CJK radicals, encoding issues), optimizes MD readability, and converts Markdown back to Word (.docx) or PDF. Installs project-local sync scripts, VS Code tasks, and Cursor rules. Handles OCR for scanned PDFs, per-sheet Markdown for Excel, legacy .ppt conversion on Windows. Use when the user mentions PDF, PPT, PPTX, DOCX, XLSX, XLSM, Excel, spreadsheets, presentations, scanned documents, asks to export Markdown as Word/DOCX/PDF, or asks to clean up / improve readability of extracted Markdown files.
---

# File Sync

Unified skill for binary-document ↔ Markdown conversion and post-processing. Three parts:

- **Binary → MD**: Sync PDF/PPT/PPTX/DOCX/XLSX/XLSM into readable Markdown
- **MD → DOCX / PDF**: Convert Markdown files to formatted Word documents or PDF files
- **MD Post-Processing**: Audit for empty files, OCR re-extract image-based documents, clean encoding artifacts, join broken lines, and optimize readability

---

## ⚠️ 交付前硬约束（Delivery Hard Constraint）

**任何** binary → MD 转换，无论是用 `tools/file_sync.py` 正式管线、还是临时写的一次性内联脚本，交付给用户前**必须**跑完以下顺序，一步不能跳：

1. Step 0：空页 / 图片页 OCR 重抽（Part C）
2. Step 1：字符清洗 `md_cleanup.py`（Part C）
3. Step 1.5：断行合并 `md_line_join.py`（PDF 类来源必做；Part C）
4. **Step 2：语义重排**（命中触发条件时必做；Part C）
5. Step 3：最终验证审计（Part C）

**只做 Step 0 就交付 = 流程违规。** 用户不需要提醒 "可读性高一点"，Step 2 由触发条件决定，不是由用户提醒决定。

内联脚本不是绕过 Part C 的借口——脚本只负责"怎么抽"，后续 5 步一条不能少。

## When To Use

- User asks to read, summarize, or analyze a PDF, PPT, PPTX, DOCX, XLSX, or XLSM file
- User drops a new binary document into the project
- User wants the sync workflow installed into a new project
- User asks to export/convert Markdown to Word (.docx) or PDF (.pdf)
- OCR output needs cleaning (scanned PDFs)
- Extracted MD has garbled CJK characters, encoding artifacts, or poor readability
- User asks to "clean up", "reformat", "improve readability", or "整理格式" of an MD file

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

7. **→ 进入 Part C，不得直接交付。** Part A 产出的是"抽出来的原始 MD"，不是"可交付的 MD"。Part C 的 Step 0→1→1.5→2→3 是交付前的硬性后处理链，参见文档顶部"交付前硬约束"。

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

## Part C: MD Post-Processing (Readability Enhancement)

After binary-to-MD extraction (Part A), the resulting Markdown often contains encoding artifacts, broken lines, and poor readability (flat `## Page N` / `## Slide N:` structure). Part C addresses all problems in order. **Every step is mandatory — do not skip any, and do not wait for user to remind you.**

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

After fixing empty files, continue with Step 1.

### Step 1: Automatic Character Cleanup

Run the built-in cleanup script on any extracted `.md` file **before** further editing:

```bash
python "<skill-dir>/scripts/md_cleanup.py" "<input.md>" --in-place
```

This fixes:

| Problem | Cause | Fix |
|---------|-------|-----|
| CJK Kangxi Radicals (`⼀⽉⾊⾸`) | PDF font CID mappings reference U+2F00 block | Mapped to standard CJK (`一月色首`) |
| CJK Radicals Supplement (`⻚⻢⻓`) | PDF fonts use U+2E80 block for simplified chars | Mapped to simplified (`页马长`) |
| Fullwidth/halfwidth mix | Inconsistent source encoding | NFKC normalization |
| Traditional residuals (`戶`) | PDF font substitution | Common trad-to-simplified pairs |
| Triple+ blank lines | Extraction artifacts | Compressed to double newlines |

For **batch processing**, pass multiple files:

```bash
python "<skill-dir>/scripts/md_cleanup.py" *.md --in-place
```

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

**Always run after `md_cleanup.py` and before AI-guided format optimization.**

### Step 2: AI-Guided Format Optimization

#### MUST trigger（不是"建议"，是"必须"）

满足以下**任意一条**，agent 必须立即执行本步骤，不得等用户提醒：

- 文件含 3+ 个 `## Page \d+` 或 `## Slide \d+:` 标题
- 所有正文行以 `- ` 开头（扁平 PPTX 提取）
- 用户显式要求 "improve readability" / "reformat" / "整理格式" / "可读性"

命中即触发。**不触发任何一条才允许跳过本步骤。**

#### Restructuring Rules

1. **Replace extraction headings with semantic headings** — `## Slide 5: 2024/9/30` becomes `### 直销-官网` based on the slide's actual content
2. **Reconstruct tables** — When consecutive lines contain structured columnar data (numbers, percentages, labels in a pattern), rebuild as Markdown pipe tables with headers
3. **Convert flat bullets to hierarchy** — Detect logical grouping (same topic, sub-items) and use nested lists or heading levels
4. **Bold key metrics** — Wrap standalone percentages, dollar amounts, and conclusion statements in `**bold**`
5. **Merge multi-page/slide sections** — If slides 6-8 all cover "亚马逊", combine under one `### 亚马逊` heading
6. **Remove noise** — Delete empty slides (`[No text extracted]`), repeated TOC slides, standalone page numbers, and date stamps that add no information
7. **NEVER fabricate content** — Do not add data, numbers, analysis, or conclusions not present in the source. When uncertain about a value, keep the original text verbatim
8. **Run cleanup first** — Always run `md_cleanup.py --in-place` before restructuring to fix encoding artifacts that would interfere with semantic parsing

#### Handling Ambiguous Extractions

- PDF charts/graphs extract as scattered numbers — keep them as-is or note `[chart data]` rather than guessing structure
- Type3 font artifacts (Latin letters substituted for CJK) are **document-specific** — do not attempt automated fix; flag for user review if detected
- When table structure is unclear, prefer preserving raw text over constructing a wrong table

### Step 3: Final Validation Audit

After all processing steps (0→1→1.5→2), **scan every output file** and verify it passes ALL checks. This is the last gate before delivering to the user.

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
| RAW_HEADINGS | Re-run Step 2 (semantic heading optimization) |
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
