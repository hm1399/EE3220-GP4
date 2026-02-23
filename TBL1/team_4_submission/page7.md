Generate an academic presentation slide (16:9, white background) titled **"Decoder Workflow — Step 3: Bounded-Distance Error Correction"**.

**Layout — decision tree on left, lookup table on right:**

**Title:** "Decoding Step 3: Syndrome Matching & Error Correction (t=3)" in navy bold.

**Left column (55%) — Decision flowchart:**

A vertical flowchart with diamond decision nodes and rectangular action nodes:

```
        [syndrome S]
             │
             ▼
      ◇ S == 0? ──YES──► "No error" (green box)
             │                err_pat = 0
            NO
             ▼
      ◇ ∃j: COL_SYN[j]==S? ──YES──► "1-bit error at position j" (light green)
             │                         err_pat = 1<<j
            NO                         64 comparisons
             ▼
      ◇ ∃j,k: COL_SYN[j]⊕   ──YES──► "2-bit error at j,k" (yellow)
        COL_SYN[k]==S?                  err_pat = (1<<j)|(1<<k)
             │                          2,016 comparisons
            NO
             ▼
      ◇ ∃j,k,l: COL_SYN[j]⊕ ──YES──► "3-bit error at j,k,l" (orange)
        COL_SYN[k]⊕                    err_pat = (1<<j)|(1<<k)|(1<<l)
        COL_SYN[l]==S?                  41,664 comparisons
             │
            NO
             ▼
      [REJECT: valid=0] (red box)
      "Uncorrectable (≥4 errors)"
```

Each decision level has a colored border: green → light-green → yellow → orange → red.
Label the left side: "Increasing search complexity".

**Right column (45%) — COL_SYN Table visualization:**

**Top: "Column Syndrome Lookup Table (COL_SYN[0..63])"**

A styled table showing a subset of the 64 entries:
| Bit Position j | COL_SYN[j] (24-bit) |
|:---:|:---:|
| 0 | FFFFFFh |
| 1 | AB77BEh |
| 2 | CDBBDC h |
| 3 | 89339Ch |
| ... | ... |
| 32 | FFFF00h |
| ... | ... |
| 63 | 800000h |

Key property highlighted in a blue box:
"All 64 entries are UNIQUE → guarantees unique decoding for weight ≤ 3"

**Bottom: Principle explanation (light yellow box):**
"COL_SYN[j] = projection of polar_transform64(unit vector e_j) onto frozen-bit positions.
Each single-bit error produces a unique 24-bit signature.
Multi-bit errors: XOR the individual signatures and match."

**Style:** Flowchart with colored decision levels, clean table, blue highlight box for key property, monospace for hex values, navy title.
