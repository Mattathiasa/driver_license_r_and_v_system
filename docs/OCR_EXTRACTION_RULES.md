# OCR Extraction Rules

This document describes how the OCR service extracts data from Ethiopian driver licenses.

## License ID Extraction

**Format**: Exactly 6 digits (e.g., `654321`)

**Extraction Logic**:
1. Search for 6 consecutive digits in left column
2. Try both normalized and raw text
3. Handle spaced digits (e.g., "6 5 4 3 2 1" → "654321")

**Examples**:
- ✅ `654321` → Extracted as `654321`
- ✅ `6 5 4 3 2 1` → Extracted as `654321`
- ❌ `A654321` → Not extracted (has letter prefix)
- ❌ `12345` → Not extracted (only 5 digits)
- ❌ `1234567` → Not extracted (7 digits)

## Grade Extraction

**Valid Types**: `Auto`, `Public 1`, `Public 2`, `02`, `Taxi 1`, `Taxi 2`

**Extraction Logic**:
1. Look for "Grade:" or "Grade" followed by text
2. Extract and normalize the text
3. Match against valid license types (exact match first)
4. Use fuzzy matching for OCR errors
5. Return the matched valid type

**Matching Rules**:

**Auto**:
- ✅ `Grade: Auto` → `Auto`
- ✅ `Grade Auto` → `Auto`
- ✅ `grade: auto` → `Auto`
- ✅ `Aut0` (OCR error) → `Auto`
- ✅ `Aulo` (OCR error) → `Auto`

**Public 1**:
- ✅ `Grade: Public 1` → `Public 1`
- ✅ `Grade Public 1` → `Public 1`
- ✅ `Public1` → `Public 1`
- ✅ `Pub1ic 1` (OCR error) → `Public 1`
- ✅ `Publ1c 1` (OCR error) → `Public 1`

**Public 2**:
- ✅ `Grade: Public 2` → `Public 2`
- ✅ `Grade Public 2` → `Public 2`
- ✅ `Public2` → `Public 2`
- ✅ `Pub1ic 2` (OCR error) → `Public 2`

**02**:
- ✅ `Grade: 02` → `02`
- ✅ `Grade 02` → `02`
- ✅ `O2` (OCR error) → `02`
- ✅ `0 2` (spaced) → `02`

**Taxi 1**:
- ✅ `Grade: Taxi 1` → `Taxi 1`
- ✅ `Grade Taxi 1` → `Taxi 1`
- ✅ `Taxi1` → `Taxi 1`
- ✅ `Tax1 1` (OCR error) → `Taxi 1`
- ✅ `Taxl 1` (OCR error) → `Taxi 1`

**Taxi 2**:
- ✅ `Grade: Taxi 2` → `Taxi 2`
- ✅ `Grade Taxi 2` → `Taxi 2`
- ✅ `Taxi2` → `Taxi 2`
- ✅ `Tax1 2` (OCR error) → `Taxi 2`

**Fallback Behavior**:
- If "public" found without number → defaults to `Public 1`
- If "taxi" found without number → defaults to `Taxi 1`
- If no match found → returns `null`

## Date of Birth (DOB) Extraction

**Format**: DD/MM/YYYY or DD MM YYYY (from right column)

**Extraction Logic**:
1. Search right column for date patterns
2. Support formats: `DD/MM/YYYY`, `DD-MM-YYYY`, `DD MM YYYY`
3. Accept years: 1900-2099
4. Convert to ISO format: `YYYY-MM-DD`

**Examples**:
- ✅ `15/05/1990` → Extracted as `1990-05-15`
- ✅ `15-05-1990` → Extracted as `1990-05-15`
- ✅ `15 05 1990` → Extracted as `1990-05-15`
- ✅ `1 5 1990` → Extracted as `1990-05-01`
- ✅ `5/12/1985` → Extracted as `1985-12-05`

## Expiry Date Extraction

**Format**: DD/MM/YYYY or DD MM YYYY (from right column, last date found)

**Extraction Logic**:
1. Find all dates in right column
2. Take the LAST date found (expiry is usually after DOB)
3. Support same formats as DOB
4. Convert to ISO format: `YYYY-MM-DD`

**Examples**:
If right column contains:
```
DOB: 15/05/1990
Expiry: 15/05/2030
```
- First date: `1990-05-15` (DOB)
- Last date: `2030-05-15` (Expiry) ✅ This is extracted

## Full Name Extraction

**Format**: All uppercase letters, 10+ characters

**Extraction Logic**:
1. Search entire text for lines with all caps
2. Minimum 10 characters
3. Only letters and spaces allowed

**Examples**:
- ✅ `ABEBE KEBEDE TESFAYE` → Extracted
- ✅ `JOHN DOE SMITH` → Extracted
- ❌ `John Doe` → Not extracted (not all caps)
- ❌ `JOHN DOE` → Not extracted (less than 10 chars)

## Column Detection

The OCR uses spatial analysis to separate left and right columns:

**Left Column** (License ID, Grade):
- License ID number
- Grade/Type
- Other license details

**Right Column** (Dates):
- Date of Birth
- Expiry Date
- Issue Date

**How it works**:
1. Calculate image midpoint (maxX / 2)
2. Text with `boundingBox.left < midX` → Left column
3. Text with `boundingBox.left >= midX` → Right column

## Text Normalization

Before extraction, text is normalized:
- `O` or `o` → `0` (letter O to zero)
- `I` or `l` → `1` (letter I/l to one)
- Multiple spaces → Single space
- Convert to lowercase

This helps with OCR errors where letters are confused with numbers.

## Debugging

To see what OCR extracted, check the debug output:

```dart
debugPrint('=== OCR Extracted Data ===');
debugPrint('License ID: ${data['licenseId']}');
debugPrint('Full Name: ${data['fullName']}');
debugPrint('Date of Birth: ${data['dateOfBirth']}');
debugPrint('License Type: ${data['licenseType']}');
debugPrint('Expiry Date: ${data['expiryDate']}');
debugPrint('OCR Raw Text: ${data['ocrRawText']}');
```

## Common Issues

### Issue: License ID not extracted
**Cause**: ID has letters or not exactly 6 digits
**Solution**: Ensure license has exactly 6 consecutive digits

### Issue: Grade not extracted
**Cause**: "Grade" keyword not found or not followed by word
**Solution**: Ensure license has "Grade:" or "Grade" followed by type

### Issue: Wrong date extracted
**Cause**: Multiple dates in right column, wrong one selected
**Solution**: Ensure expiry date is the LAST date in right column

### Issue: Dates swapped (DOB and Expiry)
**Cause**: Dates in wrong order on license
**Solution**: Check license layout - DOB should come before Expiry

## Testing

Test with various license formats:

1. **Auto License**:
   ```
   License ID: 654321
   Grade: Auto
   DOB: 15/05/1990
   Expiry: 15/05/2030
   ```

2. **Public 1 License**:
   ```
   License ID: 123456
   Grade: Public 1
   DOB: 10/03/1985
   Expiry: 10/03/2025
   ```

3. **Public 2 License**:
   ```
   License ID: 789012
   Grade: Public 2
   DOB: 20/07/1992
   Expiry: 20/07/2032
   ```

4. **02 License**:
   ```
   License ID: 345678
   Grade: 02
   DOB: 05/12/1988
   Expiry: 05/12/2028
   ```

5. **Taxi 1 License**:
   ```
   License ID: 901234
   Grade: Taxi 1
   DOB: 25/09/1995
   Expiry: 25/09/2035
   ```

6. **Taxi 2 License**:
   ```
   License ID: 567890
   Grade: Taxi 2
   DOB: 30/11/1993
   Expiry: 30/11/2033
   ```

7. **Spaced Format**:
   ```
   License ID: 6 5 4 3 2 1
   Grade: Public 1
   DOB: 1 5 1990
   Expiry: 1 5 2030
   ```

8. **Different Separators**:
   ```
   License ID: 654321
   Grade: Taxi 2
   DOB: 15-05-1990
   Expiry: 15-05-2030
   ```
