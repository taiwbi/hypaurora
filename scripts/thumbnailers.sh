#!/usr/bin/env bash
set -euo pipefail

# ffmpegthumbnailer does not advertise video/matroska on some Arch installs,
# even though xdg-mime reports that MIME type for .mkv files.

thumbnailer_file=/usr/share/thumbnailers/ffmpegthumbnailer.thumbnailer
missing_mime_type=video/matroska

if [[ ${EUID} -ne 0 ]]; then
  exec sudo -- "$0" "$@"
fi

if [[ ! -f ${thumbnailer_file} ]]; then
  echo "Error: ${thumbnailer_file} was not found." >&2
  echo "Install ffmpegthumbnailer before configuring video thumbnails." >&2
  exit 1
fi

if grep -Eq "(^|;)${missing_mime_type}(;|$)" "${thumbnailer_file}"; then
  echo "${missing_mime_type} is already registered for ffmpegthumbnailer."
  exit 0
fi

if ! grep -q '^MimeType=' "${thumbnailer_file}"; then
  echo "Error: no MimeType entry found in ${thumbnailer_file}." >&2
  exit 1
fi

sed -i -E "/^MimeType=/ s|$|${missing_mime_type};|" "${thumbnailer_file}"
echo "Registered ${missing_mime_type} for ffmpegthumbnailer."
