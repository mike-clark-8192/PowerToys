# Coding Session Handoff — FancyZones Keyboard Shortcut QoL (Feature Only)

Date: 2026-02-21  
Source: `C:\temp\fancyzones-trim.txt`, `C:\temp\fancyzones.txt`

## 1) Goal & Success Criteria

**Mission:** Improve FancyZones Editor “quick key” assignment UX by adding per-layout shortcut selectors on **custom layout cards**, supporting swap behavior, and keeping ordering/sorting intuitive.

**Success (observable):**
- Custom layout cards show a shortcut selector (0–9 + None).
- Selecting an already-assigned shortcut swaps assignments (silent).
- Selector visually indicates assignments by suffixing entries with ` - {AssignedLayoutName}`.
- Layout ordering: layouts-with-shortcuts first; layouts-without-shortcuts after (keeping existing ordering among unassigned), with no flicker.
- Edit dialog supports the same shortcut UX without breaking Save/Cancel semantics.

## 2) Requirements & Decisions (from clarifying Qs)

- **Scope:** Custom layouts only (templates unchanged).
- **“None” option:** Must exist in the selector (keep the existing “None” behavior and key ordering used by the app today).
- **Sorting:** Unassigned layouts should sort after assigned ones; unassigned layouts should keep existing behavior/order among themselves.
- **Swap feedback:** Silent (no toast/confirm).
- **Visual indicator:** Selector entries should show assignment by suffixing with layout name.
- **UI style:** Modern/minimal; started with a standard ComboBox, but switched to a compact button+popup list because the collapsed ComboBox was too wide for the available space on layout cards.
- **Interaction detail:** Click bubbling to GridView `ItemClick` is acceptable.
- **Localization:** Follow existing localization patterns.

## 3) Key Technical Context

- FancyZones Editor is **WPF** with **ModernWpf**.
- There’s an existing “quick key” concept using keys `"0"`…`"9"` plus localized `"None"`.
- The existing edit dialog already contains a quick key ComboBox for custom layouts; feature work extends this UX to layout cards and improves display.

## 4) Implementation Shape (as captured in transcript)

### 4.1 Dropdown item model (display vs value)

- Add a small DTO (e.g., `KeyDisplayItem`) with:
  - `KeyValue`: the actual key string (`"0"`…`"9"` or localized None)
  - `DisplayText`: what the UI shows (`"3 - My Layout"` vs `"3"`)

### 4.2 Shared options collection (single source of truth)

- Maintain a shared `ObservableCollection<KeyDisplayItem>` in `MainWindowSettingsModel` (e.g., `QuickKeyOptions`) that:
  - Preserves the app’s existing key ordering (including None)
  - Regenerates `DisplayText` based on current assignments
  - Is refreshed after assignment changes and layout rename/delete

### 4.3 Card UI (custom layout cards)

- Add a compact shortcut button at the bottom-right of the custom layout card template.
  - `ToggleButton` shows a compact label (e.g., `2` or `—`) and a keyboard glyph.
  - On click, opens a `Popup` containing a `ListBox` of `QuickKeyOptions` (with `DisplayText` including ` - {AssignedLayoutName}` suffixes).
- Bind the popup list:
  - `ItemsSource` → shared `QuickKeyOptions`
  - `SelectedValue` → layout’s `QuickKey`
  - `SelectedValuePath="KeyValue"`, `DisplayMemberPath="DisplayText"`
- Implementation notes:
  - `Popup` does not inherit `DataContext`; set it from `PlacementTarget.DataContext`.
  - Use a small converter (e.g., `QuickKeyToCompactDisplayConverter`) so the button shows only the compact key label.
- Ensure AutomationProperties and tooltips follow localized resources patterns.

### 4.4 Swap/assign behavior

When the user selects a new key:
- If another layout currently owns that key, swap via **two assignments** (conceptually two `SelectKey()` calls):
  - Give the current layout’s old key to the other layout
  - Assign the new key to the current layout
- Refresh shared dropdown options so suffix text updates.

### 4.5 Edit dialog Save/Cancel semantics (“pending key”)

- Avoid immediately committing swap/assignment in the edit dialog when the selection changes.
- Use a pending-selection pattern:
  - Store the original quick key on dialog open
  - Store the pending selection separately
  - Apply swap/assignment on Save only
  - Discard pending changes on Cancel

### 4.6 Sorting without flicker

Two requirements drove the approach:
- Sort on load (to handle edited files / external changes)
- No visible flicker on initial sort

Approach described in transcript:
- Sort “assigned first”, then by key number for assigned layouts.
- Keep unassigned layouts in their existing relative order.
- Prefer in-place `ObservableCollection.Move()` or CollectionView-based sorting to avoid tearing/rebinding flicker.

### 4.7 Initialization guards

- `SelectionChanged` can fire during binding/initialization; guard with an `_isInitializing` flag and “no actual change” checks.

## 5) Feature File Map (as referenced)

- `src/modules/fancyzones/editor/FancyZonesEditor/Models/KeyDisplayItem.cs` (new)
- `src/modules/fancyzones/editor/FancyZonesEditor/Models/MainWindowSettingsModel.cs`
  - Shared options (`QuickKeyOptions`), refresh method, sort method
- `src/modules/fancyzones/editor/FancyZonesEditor/Models/LayoutModel.cs`
  - Sorting helper property (e.g., `QuickKeySortOrder`)
- `src/modules/fancyzones/editor/FancyZonesEditor/MainWindow.xaml`
  - Card template compact button + popup list + edit dialog ComboBox changes
- `src/modules/fancyzones/editor/FancyZonesEditor/MainWindow.xaml.cs`
  - Card handler, swap logic, pending-key dialog logic, init guard
- `src/modules/fancyzones/editor/FancyZonesEditor/Converters/QuickKeyToCompactDisplayConverter.cs` (new)
- `src/modules/fancyzones/editor/FancyZonesEditor/App.xaml.cs`
  - Initialize refresh/sort after load

## 6) Verification Checklist (feature-only)

- Assign key on a custom layout card; verify persistence and UI label updates.
- Assign a key already used by another layout; verify swap happens and both dropdown displays update.
- Set to None; verify it unassigns and sorting updates accordingly.
- Open edit dialog, change key, press Cancel; verify no changes persisted.
- Open edit dialog, change key, press Save; verify changes persist and swap rules apply.
- Confirm layout ordering matches: assigned first; unassigned after; no flicker on startup.
