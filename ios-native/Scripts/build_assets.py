#!/usr/bin/env python3
"""
Asset builder for PetProgress
Generates placeholder pet images and builds asset catalogs
"""

import os
import json
import shutil
from pathlib import Path

# Define stage configuration
STAGES = [
    {"index": 0, "name": "Frog", "threshold": 10, "asset": "pet_frog"},
    {"index": 1, "name": "Hermit Crab", "threshold": 25, "asset": "pet_hermit"},
    {"index": 2, "name": "Seahorse", "threshold": 40, "asset": "pet_seahorse"},
    {"index": 3, "name": "Dolphin", "threshold": 55, "asset": "pet_dolphin"},
    {"index": 4, "name": "Alligator", "threshold": 75, "asset": "pet_alligator"},
    {"index": 5, "name": "Beaver", "threshold": 95, "asset": "pet_beaver"},
    {"index": 6, "name": "Wolf", "threshold": 120, "asset": "pet_wolf"},
    {"index": 7, "name": "Bear", "threshold": 145, "asset": "pet_bear"},
    {"index": 8, "name": "Bison", "threshold": 175, "asset": "pet_bison"},
    {"index": 9, "name": "Elephant", "threshold": 205, "asset": "pet_elephant"},
    {"index": 10, "name": "Rhino", "threshold": 240, "asset": "pet_rhino"},
    {"index": 11, "name": "Baby", "threshold": 285, "asset": "pet_baby"},
    {"index": 12, "name": "Toddler", "threshold": 335, "asset": "pet_toddler"},
    {"index": 13, "name": "Adult", "threshold": 390, "asset": "pet_adult"},
    {"index": 14, "name": "CEO", "threshold": 450, "asset": "pet_ceo"},
    {"index": 15, "name": "Gold", "threshold": 0, "asset": "pet_gold"}
]

def create_placeholder_image(name: str, size: tuple = (200, 200)):
    """Create a simple placeholder image using ASCII art"""
    try:
        from PIL import Image, ImageDraw, ImageFont

        img = Image.new('RGBA', size, color=(200, 200, 200, 255))
        draw = ImageDraw.Draw(img)

        # Try to use default font, fallback to no font if not available
        try:
            font = ImageFont.truetype("arial.ttf", 20)
        except:
            font = ImageFont.load_default()

        # Draw simple shape based on name
        if "frog" in name.lower():
            # Green circle for frog
            draw.ellipse([50, 50, 150, 150], fill=(50, 200, 50, 255))
        elif "hermit" in name.lower():
            # Brown square for hermit crab
            draw.rectangle([50, 50, 150, 150], fill=(139, 69, 19, 255))
        else:
            # Default blue circle
            draw.ellipse([50, 50, 150, 150], fill=(50, 50, 200, 255))

        # Add name text
        text_bbox = draw.textbbox((0, 0), name, font=font)
        text_width = text_bbox[2] - text_bbox[0]
        text_height = text_bbox[3] - text_bbox[1]
        text_x = (size[0] - text_width) // 2
        text_y = size[1] - text_height - 10
        draw.text((text_x, text_y), name, fill=(0, 0, 0, 255), font=font)

        return img

    except ImportError:
        print("PIL not available, creating text placeholder instead")
        return None

def create_imageset_contents(asset_name: str) -> dict:
    """Create Contents.json for an imageset"""
    return {
        "images": [
            {
                "filename": f"{asset_name}.png",
                "idiom": "universal",
                "scale": "1x"
            },
            {
                "filename": f"{asset_name}@2x.png",
                "idiom": "universal",
                "scale": "2x"
            },
            {
                "filename": f"{asset_name}@3x.png",
                "idiom": "universal",
                "scale": "3x"
            }
        ],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }

def create_asset_catalog(output_dir: Path):
    """Create asset catalog structure"""
    assets_dir = output_dir / "Assets.xcassets"
    assets_dir.mkdir(exist_ok=True)

    # Create Contents.json for asset catalog
    catalog_contents = {
        "info": {
            "author": "xcode",
            "version": 1
        }
    }

    with open(assets_dir / "Contents.json", "w") as f:
        json.dump(catalog_contents, f, indent=2)

    # Create AppIcon
    appicon_dir = assets_dir / "AppIcon.appiconset"
    appicon_dir.mkdir(exist_ok=True)

    appicon_contents = {
        "images": [
            {
                "idiom": "iphone",
                "scale": "2x",
                "size": "20x20"
            },
            {
                "idiom": "iphone",
                "scale": "3x",
                "size": "20x20"
            },
            {
                "idiom": "iphone",
                "scale": "2x",
                "size": "29x29"
            },
            {
                "idiom": "iphone",
                "scale": "3x",
                "size": "29x29"
            },
            {
                "idiom": "iphone",
                "scale": "2x",
                "size": "40x40"
            },
            {
                "idiom": "iphone",
                "scale": "3x",
                "size": "40x40"
            },
            {
                "idiom": "iphone",
                "scale": "2x",
                "size": "60x60"
            },
            {
                "idiom": "iphone",
                "scale": "3x",
                "size": "60x60"
            }
        ],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }

    with open(appicon_dir / "Contents.json", "w") as f:
        json.dump(appicon_contents, f, indent=2)

    # Create pet assets
    for stage in STAGES:
        asset_name = stage["asset"]
        imageset_dir = assets_dir / f"{asset_name}.imageset"
        imageset_dir.mkdir(exist_ok=True)

        # Create Contents.json for imageset
        contents = create_imageset_contents(asset_name)
        with open(imageset_dir / "Contents.json", "w") as f:
            json.dump(contents, f, indent=2)

        # Create placeholder images
        img = create_placeholder_image(stage["name"])
        if img:
            # Save at different scales
            img.save(imageset_dir / f"{asset_name}.png")
            img_2x = img.resize((400, 400))
            img_2x.save(imageset_dir / f"{asset_name}@2x.png")
            img_3x = img.resize((600, 600))
            img_3x.save(imageset_dir / f"{asset_name}@3x.png")
        else:
            # Create simple text files as placeholders
            for scale in ["", "@2x", "@3x"]:
                placeholder_path = imageset_dir / f"{asset_name}{scale}.png"
                with open(placeholder_path, "w") as f:
                    f.write(f"Placeholder for {asset_name}{scale}")

def create_stage_config(output_dir: Path):
    """Create StageConfig.json"""
    config = {"stages": STAGES}

    # Save to both App and Widget asset catalogs if they exist
    app_assets = output_dir / "App" / "Assets.xcassets"
    widget_assets = output_dir / "Widget" / "Assets.xcassets"

    for assets_dir in [app_assets, widget_assets]:
        if assets_dir.exists():
            with open(assets_dir / "StageConfig.json", "w") as f:
                json.dump(config, f, indent=2)

    # Also create in root for convenience
    with open(output_dir / "StageConfig.json", "w") as f:
        json.dump(config, f, indent=2)

def main():
    script_dir = Path(__file__).parent
    project_root = script_dir.parent

    print("Building assets for PetProgress...")

    # Create stage config
    create_stage_config(project_root)
    print("Created StageConfig.json")

    # Create asset catalogs for App and Widget
    for target in ["App", "Widget"]:
        target_dir = project_root / target
        if target_dir.exists():
            create_asset_catalog(target_dir)
            print(f"Created asset catalog for {target}")

    print("Asset building complete!")

if __name__ == "__main__":
    main()