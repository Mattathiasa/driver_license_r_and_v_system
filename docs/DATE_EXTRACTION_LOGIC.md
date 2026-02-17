# Date Extraction Logic (DOB & Expiry Date)

This document explains exactly how the OCR extracts Date of Birth and Expiry Date from Ethiopian driver licenses.

## Overview

The system uses **column-based detection** to separate the license into left and right columns, then extracts dates from the **right column only**.

## Column Detection

### Step 1: Calculate Image Midpoint
```dart
// Find the rightmost edge of all text
double maxX = 0;
for each text line:
    if (line.boundingBox.right > maxX):
        maxX = line.boundingBox.right

// Calculate midpoint
midX = maxX / 2
```

### Step 2: Separate Text into Columns
```dart
if (line.boundingBox.left < midX):
    leftColumn.add(line.text)  // License ID, Grade, etc.
else:
    rightColumn.add(line.text)  // DOB, Expiry Date
```

**Why right column?**
Ethiopian driver licenses typically have:
- **Left side**: License ID, Name, Grade, Photo
- **Right side**: DOB, Expiry Date, Issue Date

## Date of Birth (DOB) Extraction

### Logic Flow

```
1. Search right column raw text for date patterns
   ↓
2. If not found, search normalized text
   ↓
3. If not found, try spaced digit pattern
   ↓
4. Return first date found (DOB comes first)
```

### Pattern 1: Standard Date Format
**Regex**: `\b(\d{1,2})[\s/\-](\d{1,2})[\s/\-](19\d{2}|20\d{2})\b`

**Matches**:
- `15/05/1990` ✅
- `15-05-1990` ✅
- `15 05 1990` ✅
- `5/12/1985` ✅ (single digit day/month)
- `1/5/1990` ✅

**Year Range**: 1900-2099 (birth years)

**Separators**: `/`, `-`, or space

**Example**:
```
Input: "DOB: 15/05/1990"
Match: day=15, month=05, year=1990
Output: "1990-05-15"
```

### Pattern 2: Normalized Text
If Pattern 1 fails, try the same regex on normalized text (where O→0, I→1).

**Why?** OCR might read:
- `O5/O5/199O` (letter O instead of zero)
- After normalization: `05/05/1990` ✅

### Pattern 3: Spaced Digits
**Regex**: `(\d{1,2})\s+(\d{1,2})\s+(19\d{2}|20\d{2})`

**Matches**:
- `1 5 1990` ✅
- `15  5  1990` ✅ (multiple spaces)
- `5   12   1985` ✅

**Example**:
```
Input: "DOB: 1 5 1990"
Match: day=1, month=5, year=1990
Output: "1990-05-01"
```

### Date Formatting
All dates are converted to ISO format: `YYYY-MM-DD`

```dart
day = match.group(1).padLeft(2, '0')    // "5" → "05"
month = match.group(2).padLeft(2, '0')  // "1" → "01"
year = match.group(3)                   // "1990"
result = "$year-$month-$day"            // "1990-05-01"
```

## Expiry Date Extraction

### Logic Flow

```
1. Find ALL dates in right column raw text
   ↓
2. If none found, search normalized text
   ↓
3. Take the LAST date found
   ↓
4. Return as expiry date
```

### Why "Last Date"?

Ethiopian licenses typically show dates in this order:
```
DOB: 15/05/1990        ← First date
Issue: 15/05/2020      ← Middle date (optional)
Expiry: 15/05/2030     ← Last date
```

By taking the **last date**, we get the expiry date.

### Pattern: Find All Dates
**Regex**: `\b(\d{1,2})[\s/\-,](\d{1,2})[\s/\-,](20\d{2})\b`

**Year Range**: 2000-2099 (expiry dates are in the future)

**Note**: Expiry regex only accepts years starting with `20` (2000s), while DOB accepts both `19` and `20`.

**Example**:
```
Right column text:
"DOB: 15/05/1990
 Issue: 15/05/2020
 Expiry: 15/05/2030"

All matches found:
1. 15/05/1990 (DOB - but year 1990 doesn't match 20\d{2})
2. 15/05/2020 (Issue)
3. 15/05/2030 (Expiry)

Last match: 15/05/2030
Output: "2030-05-15"
```

### Fallback to Normalized Text
If no dates found in raw text, try normalized text:
```dart
if (matches.isEmpty) {
    // Try normalized text (O→0, I→1)
    matches = findAllDates(normalizedText)
}
```

## Complete Example

### License Text:
```
Left Column:          Right Column:
-----------------     -----------------
License ID: 654321    DOB: 15/05/1990
Name: ABEBE KEBEDE    Issue: 15/05/2020
Grade: Auto           Expiry: 15/05/2030
```

### Extraction Process:

**Step 1: Column Detection**
- Left: "License ID: 654321", "Name: ABEBE KEBEDE", "Grade: Auto"
- Right: "DOB: 15/05/1990", "Issue: 15/05/2020", "Expiry: 15/05/2030"

**Step 2: Extract DOB**
- Search right column: "DOB: 15/05/1990 Issue: 15/05/2020 Expiry: 15/05/2030"
- Pattern 1 matches: `15/05/1990`
- First match found → DOB = `1990-05-15` ✅

**Step 3: Extract Expiry**
- Find all dates in right column:
  1. `15/05/1990` (year 1990 - doesn't match `20\d{2}`)
  2. `15/05/2020` ✅
  3. `15/05/2030` ✅
- Take last match → Expiry = `2030-05-15` ✅

## Edge Cases

### Case 1: Only One Date in Right Column
```
Right column: "DOB: 15/05/1990"

DOB extraction: 15/05/1990 → "1990-05-15" ✅
Expiry extraction: No dates match 20\d{2} → null ❌
```

### Case 2: Dates with Different Separators
```
Right column: "DOB: 15-05-1990 Expiry: 15/05/2030"

DOB: Matches 15-05-1990 → "1990-05-15" ✅
Expiry: Matches 15/05/2030 → "2030-05-15" ✅
```

### Case 3: Spaced Digits
```
Right column: "DOB: 1 5 1990 Expiry: 1 5 2030"

DOB: Pattern 3 matches → "1990-05-01" ✅
Expiry: Pattern matches → "2030-05-01" ✅
```

### Case 4: OCR Errors (O instead of 0)
```
Right column: "DOB: O5/O5/199O Expiry: O5/O5/2O3O"

Raw text: No matches
Normalized text (O→0): "05/05/1990" and "05/05/2030"
DOB: "1990-05-05" ✅
Expiry: "2030-05-05" ✅
```

## Date Format Output

All dates are returned in **ISO 8601 format**: `YYYY-MM-DD`

**Why?**
- Standard format for databases
- Easy to parse and compare
- Unambiguous (no confusion between DD/MM vs MM/DD)

**Examples**:
- Input: `15/05/1990` → Output: `1990-05-15`
- Input: `5/12/1985` → Output: `1985-12-05`
- Input: `1 5 1990` → Output: `1990-05-01`

## Debugging

To see what dates were extracted:

```dart
debugPrint('Right column text: $rightTextRaw');
debugPrint('DOB extracted: ${data['dateOfBirth']}');
debugPrint('Expiry extracted: ${data['expiryDate']}');
```

## Common Issues

### Issue: DOB not extracted
**Possible causes**:
1. Date is in left column (should be in right)
2. Year format is wrong (not 19XX or 20XX)
3. Separators are unusual (not /, -, or space)

**Solution**: Check license layout and date format

### Issue: Expiry not extracted
**Possible causes**:
1. Expiry date year is before 2000 (regex requires 20XX)
2. Only one date in right column (DOB)
3. Expiry date is in left column

**Solution**: Ensure expiry date is in right column with year 20XX

### Issue: Dates are swapped
**Possible causes**:
1. License has expiry date before DOB
2. Multiple dates confusing the extraction

**Solution**: Check license layout - DOB should come before Expiry

### Issue: Wrong date extracted
**Possible causes**:
1. Multiple dates in right column
2. Issue date being picked instead of expiry

**Solution**: Ensure expiry is the LAST date in right column

## Summary

**DOB Logic**: Take the **FIRST** date found in right column (years 1900-2099)

**Expiry Logic**: Take the **LAST** date found in right column (years 2000-2099)

**Column Detection**: Split image at midpoint (left vs right)

**Format**: Output as `YYYY-MM-DD` (ISO 8601)

**Fallback**: Try normalized text if raw text fails
