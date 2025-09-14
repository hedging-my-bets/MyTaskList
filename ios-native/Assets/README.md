# Pet Evolution Assets

This directory contains the visual assets for all 16 pet evolution stages.

## Stage Assets (Required)

The following image files should be placed in this directory:

### Baby Stages (0-3)
- `pet_baby.png` - Stage 0 (0 points)
- `pet_toddler.png` - Stage 1 (10 points)
- `pet_frog.png` - Stage 2 (25 points)
- `pet_hermit.png` - Stage 3 (45 points)

### Growth Stages (4-7)
- `pet_seahorse.png` - Stage 4 (70 points)
- `pet_dolphin.png` - Stage 5 (100 points)
- `pet_alligator.png` - Stage 6 (135 points)
- `pet_beaver.png` - Stage 7 (175 points)

### Maturity Stages (8-11)
- `pet_wolf.png` - Stage 8 (220 points)
- `pet_bear.png` - Stage 9 (270 points)
- `pet_bison.png` - Stage 10 (325 points)
- `pet_elephant.png` - Stage 11 (385 points)

### Elite Stages (12-15)
- `pet_rhino.png` - Stage 12 (450 points)
- `pet_adult.png` - Stage 13 (520 points)
- `pet_ceo.png` - Stage 14 (595 points)
- `pet_gold.png` - Stage 15 (675 points)

## Asset Requirements

- Format: PNG preferred, JPEG/HEIC acceptable
- Recommended size: 64x64px minimum, 512x512px maximum
- Transparent backgrounds preferred
- Square aspect ratio (1:1)

## Fallback System

If assets are missing, the app will use SF Symbol placeholders:
- Numbered circles (1.circle.fill through 16.circle.fill)
- Deterministic and predictable
- Maintains visual progression

## Validation

Use `AssetPipeline.shared.validate()` to check asset completeness.