#!/bin/bash

set -e

REPO_DIR="/home/loopsign/ls-x86intel"
THEME_NAME="loopsign"
THEME_DIR="/usr/share/plymouth/themes/$THEME_NAME"
SPLASH_IMAGE="$REPO_DIR/splash.png"

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root:"
    echo "sudo $0"
    exit 1
fi

if [ ! -f "$SPLASH_IMAGE" ]; then
    echo "ERROR: Missing splash image:"
    echo "$SPLASH_IMAGE"
    exit 1
fi

mkdir -p "$THEME_DIR"

cp "$SPLASH_IMAGE" "$THEME_DIR/splash.png"

cat > "$THEME_DIR/$THEME_NAME.plymouth" <<EOF
[Plymouth Theme]
Name=LoopSign
Description=LoopSign boot splash
ModuleName=script

[script]
ImageDir=$THEME_DIR
ScriptFile=$THEME_DIR/$THEME_NAME.script
EOF

cat > "$THEME_DIR/$THEME_NAME.script" <<'EOF'
wallpaper_image = Image("splash.png");
screen_width = Window.GetWidth();
screen_height = Window.GetHeight();

image_width = wallpaper_image.GetWidth();
image_height = wallpaper_image.GetHeight();

scale_x = screen_width / image_width;
scale_y = screen_height / image_height;

if (scale_x > scale_y) {
    scale = scale_x;
} else {
    scale = scale_y;
}

resized_image = wallpaper_image.Scale(image_width * scale, image_height * scale);

resized_width = resized_image.GetWidth();
resized_height = resized_image.GetHeight();

wallpaper_sprite = Sprite(resized_image);
wallpaper_sprite.SetX((screen_width - resized_width) / 2);
wallpaper_sprite.SetY((screen_height - resized_height) / 2);
wallpaper_sprite.SetZ(-100);
EOF

plymouth-set-default-theme "$THEME_NAME"
update-initramfs -u

echo "LoopSign Plymouth theme installed and activated."
