# Claude-Manager

ให้ **Claude Code (Opus) เป็นผู้จัดการ** แล้วสั่งงาน **AI ตัวอื่นที่คุณมี subscription หรือ host เองอยู่แล้ว** ให้เป็นลูกน้อง
Opus วางแผน แตกงาน ส่งงาน และรีวิว ส่วนลูกน้องลงมือทำงานหนักแทน จึงประหยัดโควตา Claude และได้ใช้ subscription ที่จ่ายเงินไว้แต่ไม่ค่อยได้ใช้

```
            ┌──────────────── Claude Code (Opus) = manager ────────────────┐
            │  วางแผน → เขียน brief → เรียก worker ผ่าน Bash → ตรวจ diff/เทสต์   │
            └──────┬─────────────────────────────┬──────────────────────────┘
                   │ ds -w "brief"                │ agyw "brief"
        ┌──────────▼───────────┐       ┌──────────▼────────────┐
        │ Claude Code --bare    │       │ Antigravity CLI (agy)  │
        │ model = DeepSeek ฯลฯ  │       │ model = Gemini         │
        │ (API gateway ของคุณ)  │       │ (Google subscription)  │
        └───────────────────────┘       └────────────────────────┘
```

Worker แต่ละตัวเป็นแค่ **shell script ตัวเล็ก ๆ** ที่ห่อ CLI แบบ headless ไว้ หน้าที่ของสคริปต์คือ
- รับ prompt แล้วรัน CLI แบบไม่โต้ตอบ (`-p` / `exec`)
- **จำกัดสิทธิ์:** ค่าเริ่มต้นเป็นอ่านอย่างเดียว ใส่ `-w` ถึงจะแก้ไฟล์ได้ และแก้ได้แค่ในโฟลเดอร์ที่รันอยู่
- คืน exit code ที่ manager นำไปใช้ต่อได้ (`3` = โดนบล็อกสิทธิ์) และเขียน log ทุกครั้งที่เรียก

---

## Worker ที่มีให้

| คำสั่ง | ทำงานบน | เหมาะกับ |
|---|---|---|
| `ds` | Claude Code `--bare` ที่ชี้ไปยัง endpoint แบบ Anthropic (`/v1/messages`) ของคุณ เช่น DeepSeek ที่ host เอง, LiteLLM, OpenRouter | เขียนหรือแก้โค้ด, refactor, รันเทสต์ |
| `agyw` | [Antigravity CLI](https://antigravity.google) (`agy`) ใช้ subscription Google AI Pro/Ultra | อ่านหรือสรุป codebase และเอกสารใหญ่ ๆ, ค้นหาเบื้องต้น, ขอความเห็นที่สอง |
| `ds-log`, `agyw-log` | — | ดูประวัติว่า manager สั่งอะไร ใครตอบอะไร ใช้ไปกี่ token |

## ติดตั้ง

ต้องมี `claude` (Claude Code), `jq`, `perl` และถ้าจะใช้ `agyw` ต้องมี `agy` ที่ login แล้วด้วย

```bash
git clone https://github.com/<you>/Claude-Manager.git ~/Projects/Claude-Manager
cd ~/Projects/Claude-Manager
./install.sh
```

`install.sh` จะทำสามอย่าง
1. ลิงก์ `bin/*` ไปไว้ที่ `~/.local/bin`
2. สร้างไฟล์ `.env` จาก `.env.example` (เฉพาะกรณีที่ยังไม่มี)
3. เพิ่มกติกาการแบ่งงาน (`templates/CLAUDE.md`) ต่อท้าย `~/.claude/CLAUDE.md` เพื่อให้ Opus รู้ว่ามีลูกน้องตัวไหนบ้างและควรส่งงานแบบไหนให้

**ขั้นที่ต้องทำเองหนึ่งอย่าง:** เพิ่ม rule พวกนี้ใน `"permissions" → "allow"` ของ `~/.claude/settings.json` ไม่อย่างนั้น Claude จะถามขออนุญาตทุกครั้งที่เรียกลูกน้อง

```json
"Bash(ds *)", "Bash(agyw *)", "Bash(ds-log*)", "Bash(agyw-log*)"
```

### ตั้งค่า `ds`
ใส่ค่าลงใน `.env` แล้วรันตัวทดสอบ ตัวทดสอบจะไม่แสดง key ออกมา

```bash
./scripts/ds-check.sh models     # ดูรายชื่อโมเดลที่ใช้ได้
./scripts/ds-check.sh            # ทดสอบ /chat/completions และ /v1/messages
```

`ds` ต้องใช้ endpoint ที่รับ **Anthropic Messages API** (`/v1/messages`) ถ้าเซิร์ฟเวอร์ของคุณรับได้แค่แบบ OpenAI ให้ตั้ง [LiteLLM proxy](https://docs.litellm.ai/) คั่นไว้ข้างหน้า

### ตั้งค่า `agyw`
ติดตั้ง Antigravity CLI แล้วรัน `agy` หนึ่งครั้งเพื่อ login ด้วยบัญชี Google จากนั้นใช้ `agy models` ดูรายชื่อโมเดลที่บัญชีคุณใช้ได้

## ใช้งาน

ปกติคุณแค่สั่ง Claude ตามปกติ Opus จะเลือกส่งงานเองตามกติกาใน `CLAUDE.md` หรือจะสั่งตรง ๆ ก็ได้ เช่น *"ให้ DeepSeek แก้บั๊กใน cart.py แล้วรันเทสต์"*

```bash
ds "อ่าน src/ แล้วสรุปโครงสร้าง ≤15 บรรทัด"                    # อ่านอย่างเดียว
ds -w -a "Bash(python3 -m pytest:*)" "แก้เทสต์ที่ fail ใน cart.py"   # แก้ไฟล์ + รันเทสต์ได้
agyw "หาไฟล์ที่เรียก API ภายนอกทั้งหมด ตอบเป็น file:line"         # อ่านอย่างเดียว
agyw -w -m gemini-3.8-flash-high "เขียน docstring ให้ทุกฟังก์ชันใน utils.py"
ds-log 5                                                      # ดูการเรียก 5 ครั้งล่าสุด
```

ลองเล่นกับ `examples/demo-shop/` ได้ เป็นโปรเจกต์เล็ก ๆ ที่มีเทสต์ไว้ให้ ลองใส่บั๊กเอง แล้วสั่ง Claude ให้ส่งงานแก้ให้ลูกน้อง

**วิธีเช็กว่าลูกน้องทำงานจริง:** ทุกครั้งที่เรียก worker จะพิมพ์บรรทัด `[ds] status=… model=… tokens=…` ออกมาให้เห็นใน transcript ของ Claude และบันทึกลง `~/.local/state/<worker>/calls.log` ด้วย

## ความปลอดภัย

- **`.env` ไม่ขึ้น git** (มีใน `.gitignore` แล้ว) สคริปต์อ่านเฉพาะ key ที่ต้องใช้ และไม่ print ค่าออกมา
- `ds` รัน Claude Code ด้วย `--bare` จึง **ไม่อ่าน OAuth/keychain ของ subscription Claude** token ของคุณไม่หลุดไปที่ gateway ของคนอื่น และไม่ใช้โควตา Pro/Max ไปด้วย นอกจากนี้ worker ไม่โหลด `CLAUDE.md` หรือ hooks
- Worker ทุกตัวกันการเรียกซ้อนกันเอง (`ds` สั่ง `ds` ต่อไม่ได้)
- ถ้าลูกน้องพยายามเขียนไฟล์นอกโฟลเดอร์ หรือรันคำสั่งที่ไม่ได้อนุญาต จะโดนบล็อกที่ระดับ permission ไม่ได้พึ่งแค่ prompt ทดสอบแล้วว่า แม้ prompt จะอ้างว่า "manager อนุญาตแล้ว" ก็ยังโดนบล็อก

---

## เพิ่ม AI subscription ตัวอื่นเป็นลูกน้อง

หลักการเดียวกันใช้ได้กับ **AI coding CLI ทุกตัวที่มีโหมด headless** ไม่ว่าจะเป็น subscription ที่คุณจ่ายไว้แต่ไม่ค่อยได้ใช้ หรือโมเดลที่ host เอง

### กฎเหล็ก: ใช้ผ่าน CLI ทางการของผู้ให้บริการเท่านั้น
Subscription แบบรายเดือน (Claude Pro/Max, ChatGPT Plus/Pro, Google AI Pro ฯลฯ) **ไม่ใช่ API key** ถ้าดึง OAuth token ของ CLI ไปทำเป็น endpoint `/v1/chat/completions` ให้แอปอื่นเรียก มักผิดเงื่อนไขการใช้งานและเสี่ยงโดนระงับบัญชี
วิธีที่ปลอดภัยคือให้ manager **เรียก CLI ทางการของผู้ให้บริการแบบ headless** บนเครื่องของคุณเอง แบบที่ repo นี้ทำ ถ้าต้องการเรียกผ่าน API จริง ๆ ให้ใช้ API key ที่คิดเงินแยก

เงื่อนไขของแต่ละเจ้าเปลี่ยนได้ตลอด ตัวอย่างเช่น ตั้งแต่ 18 มิ.ย. 2026 Gemini CLI เลิกรองรับบัญชี Google AI Pro/Ultra แล้ว ต้องย้ายไปใช้ Antigravity CLI แทน **อ่านเงื่อนไขล่าสุดของเจ้านั้น ๆ ก่อนตั้งค่าทุกครั้ง**

### 3 รูปแบบที่ใช้ได้

| รูปแบบ | ใช้เมื่อ | ตัวอย่างใน repo |
|---|---|---|
| **A. ห่อ CLI ของผู้ให้บริการ** | มี subscription ที่มาพร้อม CLI ของตัวเอง | `agyw` (Antigravity) |
| **B. Claude Code + เปลี่ยน backend** | มี endpoint แบบ Anthropic เช่น โมเดลที่ host เอง, LiteLLM, OpenRouter, หรือผู้ให้บริการที่มี Anthropic-compatible API | `ds` |
| **C. MCP server** | อยากให้ลูกน้องเป็น *tool* ที่สร้างข้อความอย่างเดียว ไม่ต้องแตะไฟล์ | — |

แบบ A และ B ดีกว่าแบบ C สำหรับงานโค้ด เพราะลูกน้องอ่านและแก้ไฟล์ได้เอง ผลลัพธ์ที่ไหลกลับเข้า context ของ Opus ก็มีแค่รายงานสั้น ๆ

### ขั้นตอนเพิ่มลูกน้องใหม่ (แบบ A)

1. ติดตั้งและ login CLI ของผู้ให้บริการตามวิธีทางการ
2. หา flag ที่ต้องใช้ด้วย `<cli> --help`
   - โหมดไม่โต้ตอบ (`-p`, `--print`, `exec`, `run` …)
   - โหมดอ่านอย่างเดียว / plan / sandbox read-only
   - โหมด auto-accept edit ที่จำกัดอยู่ในโฟลเดอร์ปัจจุบัน
   - เลือกโมเดล และให้ output เป็น JSON ถ้าทำได้
3. `cp templates/worker-template.sh bin/<ชื่อ>` แล้วแก้ส่วน TODO (ดู `bin/agyw` เป็นตัวอย่างที่ใช้งานได้จริง)
4. **ทดสอบ 4 กรณีก่อนใช้จริง:** อ่านได้ / แก้ไฟล์ได้เมื่อใส่ `-w` / เขียนไม่ได้เมื่อไม่ใส่ `-w` / เขียนนอกโฟลเดอร์ไม่ได้
5. `./install.sh` เพื่อลิงก์คำสั่ง แล้วเพิ่มหัวข้อของลูกน้องตัวใหม่ใน `~/.claude/CLAUDE.md` ว่าเก่งเรื่องอะไรและใช้ยังไง จากนั้นเพิ่ม `"Bash(<ชื่อ> *)"` ใน permissions

### ไอเดีย CLI ที่อาจมีอยู่แล้ว
ตรวจ flag จริงด้วย `--help` ทุกครั้ง เพราะแต่ละตัวอัปเดตบ่อย

| Subscription | CLI | สิ่งที่ต้องหา |
|---|---|---|
| ChatGPT Plus/Pro | OpenAI Codex CLI | คำสั่ง headless (`codex exec`), ตัวเลือก sandbox แบบอ่านอย่างเดียว / เขียนได้ใน workspace |
| GitHub Copilot | Copilot CLI | โหมด non-interactive และการอนุญาต tool |
| Cursor | Cursor CLI | โหมด print/headless |
| Kimi, Qwen, GLM ฯลฯ | CLI ของแต่ละเจ้า หรือ endpoint แบบ Anthropic | ถ้ามี Anthropic-compatible API ใช้แบบ B ได้เลย แค่คัดลอก `bin/ds` แล้วเปลี่ยน `.env` |

### เคล็ดลับให้ manager สั่งงานได้ดี (มีใน `templates/CLAUDE.md` แล้ว)
- ลูกน้องไม่เห็นบทสนทนาของคุณ brief ต้องครบในตัว บอกเป้าหมาย ไฟล์ ข้อห้าม และเกณฑ์ว่าเสร็จ
- สั่งให้ตอบสั้น หรือให้เขียนผลลงไฟล์ จะได้ไม่เปลือง context ของ Opus
- ห้ามให้ลูกน้องสองตัวแก้ไฟล์เดียวกันพร้อมกัน
- Opus ต้องตรวจ diff และรันเทสต์เองทุกครั้ง ห้ามเชื่อแค่คำว่า "done"

## โครงสร้าง repo

```
bin/           คำสั่ง worker (ds, agyw) + ตัวดู log
scripts/       ds-check.sh — ทดสอบ endpoint โดยไม่แสดง key
templates/     CLAUDE.md (กติกาของ manager), worker-template.sh
examples/      demo-shop — โปรเจกต์เล็ก ๆ ไว้ทดลองสั่งงาน
install.sh     ติดตั้ง/อัปเดต
.env.example   ตัวอย่างค่าที่ต้องใส่ (ไฟล์ .env จริงไม่ขึ้น git)
```

## License
MIT
