from PIL import Image, ImageDraw, ImageFont
import os

# Create app icon (1024x1024)
size = 1024
img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Draw purple background with rounded corners
purple_color = (94, 53, 177, 255)  # #5E35B1
draw.rounded_rectangle([(0, 0), (size, size)], radius=size//5, fill=purple_color)

# Draw white "Z" letter
white_color = (255, 255, 255, 255)
try:
    # Try to use a bold font
    font = ImageFont.truetype("arial.ttf", size=int(size * 0.6))
except:
    # Fallback to default font
    font = ImageFont.load_default()
    # Scale up the text for default font
    font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", size=int(size * 0.6))

# Get text bbox for centering
text = "Z"
bbox = draw.textbbox((0, 0), text, font=font)
text_width = bbox[2] - bbox[0]
text_height = bbox[3] - bbox[1]

# Calculate position to center the text
x = (size - text_width) // 2
y = (size - text_height) // 2 - bbox[1]

# Draw the "Z"
draw.text((x, y), text, fill=white_color, font=font)

# Save the main icon
os.makedirs("assets/images", exist_ok=True)
img.save("assets/images/app_icon.png")
print("Created app_icon.png")

# Create foreground icon for adaptive icon (Android)
# This should be the "Z" on transparent background
img_foreground = Image.new('RGBA', (size, size), (0, 0, 0, 0))
draw_foreground = ImageDraw.Draw(img_foreground)
draw_foreground.text((x, y), text, fill=white_color, font=font)
img_foreground.save("assets/images/app_icon_foreground.png")
print("Created app_icon_foreground.png")

print("Icons created successfully!")