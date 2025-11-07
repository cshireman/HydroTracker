# Water Tracker — Low‑Fi Wireframes (iPhone & Apple Watch)

*(Monochrome, structure‑first sketches to guide SwiftUI layout. Copy is indicative only.)*

---

### iPhone — Home (Today)
```
┌──────────────────────────────────────────────┐
│  Today · Mon, Nov 3                          │
│  [Settings⚙︎]                                 │
│                                              │
│              ◯  PROGRESS RING                │
│            56 oz / 80 oz (70%)               │
│                                              │
│  Presets                                     │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ │
│  │ 8 oz   │ │ 12 oz  │ │ 16 oz  │ │ + Custom│ │
│  └────────┘ └────────┘ └────────┘ └────────┘ │
│                                              │
│  Today Log                                   │
│  ┌──────────────────────────────────────────┐ │
│  │ 12 oz · 12:41 PM            ⋯ (swipe)    │ │
│  ├──────────────────────────────────────────┤ │
│  │ 8 oz  · 11:02 AM            ⋯            │ │
│  ├──────────────────────────────────────────┤ │
│  │ 16 oz · 9:10 AM             ⋯            │ │
│  └──────────────────────────────────────────┘ │
│                                              │
│  Toolbar: [History]      [Add +]      [Goals]│
└──────────────────────────────────────────────┘
```
**Interactions**
- Tapping a preset instantly adds with haptic; ring animates.
- “+ Custom” opens numeric keypad sheet.
- Swipe left on a row → Edit / Delete.
- “Add +” mirrors “+ Custom” for thumb reach.

---

### iPhone — Custom Amount Sheet
```
┌──────── Add Water ────────┐
│ Amount                     │
│ [  12.0 ]  [oz ▾]         │  ← numeric keypad below
│ [ -0.5 ][ +0.5 ]          │
│ [ Cancel ]   [ Add ]      │
└───────────────────────────┘
```
- Unit toggle switches between oz/ml; value converts live.

---

### iPhone — Settings
```
┌──────── Settings ─────────┐
│ Units               [oz ▾] │
│ Daily Goal          [80 oz]│
│ Presets (tap to edit)      │
│  • 8 oz  • 12 oz  • 16 oz  │
│ Health                     │
│  Write to Health   [ ☐ ]   │
│ Reminders                  │
│  Schedule          [ ▸ ]   │
│ Widgets & Lock Screen [ ▸ ]│
│ About / Privacy     [ ▸ ]  │
└────────────────────────────┘
```

---

### iPhone — Edit Preset
```
┌───── Edit Presets ─────┐   (drag to reorder)
│ ☰ 8 oz                 │
│ ☰ 12 oz                │
│ ☰ 16 oz                │
│ [+ Add preset]         │  (limit 4)
└────────────────────────┘
```

---

### iPhone — History (Optional MVP)
```
┌──────── History ────────┐
│ Week of Oct 27–Nov 2     │
│  Sun 80/80  Mon 72/80 ...│  (bars or mini‑rings)
│ List by day              │
│  Mon                     │
│   • 12:41 12 oz          │
│   • 11:02 8 oz           │
│  Sun                     │
│   • …                    │
└──────────────────────────┘
```

---

### Apple Watch — Primary Logging
```
┌──────────────────────────┐
│   ◯ 56/80 oz             │  small ring + number
│                          │
│ [ 8 oz ]   [ 12 oz ]     │  big tappable buttons
│ [ 16 oz ]                 │
│ [ Crown to set  ————▮ ]  │  hint: rotate to fine‑tune
│ [ + Custom ]              │
└──────────────────────────┘
```
**Interactions**
- Tapping a preset gives haptic + toast “Added 8 oz”.
- Rotating crown reveals a live amount row; press to confirm add.

---

### Apple Watch — Custom Amount
```
┌──── Add Water ────┐
│ Amount            │
│  12.0 [oz ▾]      │ (± via crown)
│ [ Cancel ] [ Add ]│
└───────────────────┘
```

---

### Apple Watch — Today List
```
┌──────── Today ────────┐
│ 56/80 oz  (ring)       │
│ 12:41  12 oz   (•••)   │  ← swipe/long‑press → Delete
│ 11:02   8 oz           │
│  9:10  16 oz           │
└────────────────────────┘
```

---

### Complications (at‑a‑glance)
- **Circular**: ring + current/goal (e.g., 56/80).
- **Inline**: “Water 70%”.
- **Rectangular**: ring + small total chartlet (later).

---

### Navigation Flow (MVP)
```
[iPhone Home]
   ├─→ [Custom Amount Sheet]
   ├─→ [Settings]
   │      ├─→ [Edit Presets]
   │      └─→ [Reminders]
   └─→ [History] (optional)

[Watch Home]
   ├─→ [Custom Amount]
   └─→ [Today List]
```

---

### Layout & Components Notes
- Use SwiftUI `Grid` or `HStack`/`VStack` for presets; ensure hit area ≥ 44pt.
- Progress ring: `Gauge` with custom style, App Group shared data for widgets.
- Haptics: light impact on add; success notification on goal reached.
- Accessibility: VoiceOver labels (“Add 8 ounces”), Dynamic Type XL support.

---

### Next Steps
- Turn iPhone Home into a SwiftUI preview with sample data.
- Implement a reusable `AmountStepper` (±0.5 oz / 10 ml) for both platforms.
- Define App Icon & color tokens (brand later; grayscale now).

