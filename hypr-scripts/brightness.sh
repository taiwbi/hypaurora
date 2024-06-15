#!/bin/bash

calculate_dark() {
	# h(x)=25000+((4000-25000)/(1+(((x)/(10000)))^(2.6)))
	local x=$1

  local a=25000
  local b=4000
  local c=10000
  local d=2.6

  # Calculate the intermediate values
  local denominator=$(echo "1 + ($x / $c)^$d" | bc -l)
  local fraction=$(echo "($b - $a) / $denominator" | bc -l)

  # Calculate the final value of y
  local y=$(echo "$a + $fraction" | bc -l)

  echo "$y"
}

calculate_light() {
  # f(x)=29500+((3500-29500)/(1+(((x)/(24000)))^(4)))
  local x=$1

  # Constants in the equation
  local a=29500
  local b=3500
  local c=24000
  local d=4

  # Calculate the intermediate values
  local denominator=$(echo "1 + ($x / $c)^$d" | bc -l)
  local fraction=$(echo "($b - $a) / $denominator" | bc -l)

  # Calculate the final value of y
  local y=$(echo "$a + $fraction" | bc -l)

  echo "$y"
}

# Define the file path for the captured image
image_file="room_capture.jpg"

# Define a temporary file for the grayscale version of the image
gray_image_file="room_capture_gray.jpg"

# Number of images to capture
num_images=3

# Capture multiple images using fswebcam
for ((i = 1; i <= $num_images; i++)); do
	fswebcam --set brightness=100% --set contrast=20% --resolution "640x360" --no-banner "${image_file}_${i}.jpg"
done

# Choose the image with the most stable exposure level (assumes it's the one with the median brightness)
brightness_array=()
for ((i = 1; i <= $num_images; i++)); do
	convert "${image_file}_${i}.jpg" -colorspace gray "${gray_image_file}_${i}.jpg"
	brightness=$(convert "${gray_image_file}_${i}.jpg" -format "%[mean]" info:)
	brightness_array+=("$brightness")
	sleep 0.2
done

sum=0
for num in "${brightness_array[@]}"; do
  sum=$(bc -l <<< "$sum + $num")
done

# Choose the median brightness value
median_brightness="$(bc -l <<< "scale=2; $sum / $num_images")"

echo "Median Brightness: $median_brightness"

# Light Mode: 33000 < median
if [[ "$(printf "%.0f" "$median_brightness")" -gt 27500 ]]; then
	echo "Light Mode"
	gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
	result=$(calculate_light "$median_brightness")
	result=$(echo "scale=2; $result / 2" | bc)

# Dark Mode
else
	echo "Dark Mode"
	gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
	result=$(calculate_dark "$median_brightness")
fi

echo "Brightness level: $result"
brightnessctl set "$result"

notify-send -i "display-brightness-symbolic" -a "Adaptive Brightness" -- "Brightness Changed" "Median Brightness: $median_brightness | Brightness level set: $result"

# Clean up - delete the captured and temporary images
rm "${image_file}"_* "${gray_image_file}"_*
