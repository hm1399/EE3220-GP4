Generate an academic presentation slide (16:9, white background) titled **"Verification & Summary"**.

**Layout — left: test results table, right: summary points:**

**Title:** "Verification Results & Summary" in navy bold.

**Left column (55%) — Test Results Table (tb_basic.sv):**

A professional styled results table:

| Test Case | Error Injection | Expected | Result |
|:---|:---:|:---:|:---:|
| Case A: 0 flips | None | valid=1, data=ABCDEF | ✅ PASS |
| Case B-1: 1 flip (bit 5) | 1 bit | valid=1, data=ABCDEF | ✅ PASS |
| Case B-2: 2 flips (bit 0,63) | 2 bits | valid=1, data=ABCDEF | ✅ PASS |
| Case B-3: 3 flips (bit 0,1,63) | 3 bits | valid=1, data=ABCDEF | ✅ PASS |
| Case C: 4 flips (bit 0,1,2,3) | 4 bits | valid=0 (reject) | ✅ PASS |
| Fail-safe: 5 flips | 5 bits | valid=0 or correct | ✅ PASS |

All rows with light green background and green checkmarks.

Below the table, a green badge: "SMOKE SCORE: 30/30"

Below that, a small note in gray: "tb_basic is a smoke test; full grading uses tb_hidden with randomized regression."

**Right column (45%) — System Summary:**

**Top: Key metrics cards (2x2 grid of small cards):**
- Card: "Code Rate: 0.625"
- Card: "d_min = 8"
- Card: "Correction: ≤3 bits"
- Card: "Detection: 4 bits"

**Middle: Design highlights checklist:**
- ✅ Shared parameter package ensures encoder/decoder consistency
- ✅ CRC-16 provides secondary error detection
- ✅ Column syndrome table enables unique error identification
- ✅ Safety-first: valid=0 when uncertain
- ✅ 2-cycle pipelined encoder & decoder

**Bottom: Safety principle banner (navy background, white text):**
"Design Rule: Never output incorrect data with valid=1. Reject when in doubt."

**Style:** Clean academic, green for pass/success, navy banner, metric cards with light blue background, checkmark list, professional table.
