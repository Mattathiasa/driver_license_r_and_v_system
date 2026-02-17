# Ethiopian Driver License Types

This document lists all valid license types (grades) in the system.

## Valid License Types

The system recognizes exactly 6 license types:

1. **Auto** - Automatic transmission vehicles
2. **Public 1** - Public transport category 1
3. **Public 2** - Public transport category 2
4. **02** - Special category 02
5. **Taxi 1** - Taxi category 1
6. **Taxi 2** - Taxi category 2

## OCR Recognition

The OCR system will automatically match extracted text to these valid types:

### Auto
- Matches: `Auto`, `auto`, `AUTO`, `Aut0`, `Aulo`
- Example: `Grade: Auto` → `Auto`

### Public 1
- Matches: `Public 1`, `public 1`, `Public1`, `Pub1ic 1`, `Publ1c 1`
- Example: `Grade: Public 1` → `Public 1`
- Default: If only "public" is found → `Public 1`

### Public 2
- Matches: `Public 2`, `public 2`, `Public2`, `Pub1ic 2`, `Publ1c 2`
- Example: `Grade: Public 2` → `Public 2`

### 02
- Matches: `02`, `O2`, `o2`, `0 2`
- Example: `Grade: 02` → `02`

### Taxi 1
- Matches: `Taxi 1`, `taxi 1`, `Taxi1`, `Tax1 1`, `Taxl 1`
- Example: `Grade: Taxi 1` → `Taxi 1`
- Default: If only "taxi" is found → `Taxi 1`

### Taxi 2
- Matches: `Taxi 2`, `taxi 2`, `Taxi2`, `Tax1 2`, `Taxl 2`
- Example: `Grade: Taxi 2` → `Taxi 2`

## Manual Entry

When manually entering license data, use exactly these formats:
- `Auto`
- `Public 1`
- `Public 2`
- `02`
- `Taxi 1`
- `Taxi 2`

## Database Storage

License types are stored as strings in the database exactly as shown above.

## Validation

The backend validates license types against this list. Invalid types will be rejected.

## Common OCR Errors

The system handles these common OCR misreads:

| Correct | OCR Error | Handled |
|---------|-----------|---------|
| Auto | Aut0 | ✅ |
| Auto | Aulo | ✅ |
| Public 1 | Pub1ic 1 | ✅ |
| Public 1 | Publ1c 1 | ✅ |
| 02 | O2 | ✅ |
| 02 | 0 2 | ✅ |
| Taxi 1 | Tax1 1 | ✅ |
| Taxi 1 | Taxl 1 | ✅ |
| Taxi 2 | Tax1 2 | ✅ |
| Taxi 2 | Taxl 2 | ✅ |

## Notes

- License types are case-insensitive during OCR extraction
- Stored in database with proper capitalization
- Spaces in type names (e.g., "Public 1") are preserved
- OCR fuzzy matching helps with common recognition errors
