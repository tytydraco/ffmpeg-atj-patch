# ffmpeg-yp3-patch

Patched FFMPEG for Shenju / YP3 H.264 MP3 players.

# Why

H.264 YP3-chip decoders require legacy FFMPEG parameters that cannot be set via command line options. Instead, a minimal patch is necessary.

Without this patch, modern FFMPEG-encoded videos will not play, or will be severely corrupted. This is primarily due to mismatching SPS/PPS and VUI data.

# Credit

- Cursor: File analysis, bisect assistance, stress testing.
- [fdd4s](https://github.com/fdd4s/portable_music_player_avi_video_converter_tool_2025): Shenju vendor-patched `ffmpeg.exe` as reference, and initial working encoding parameters.

# Patch

- `i_nal_ref_idc = NAL_PRIORITY_DISPOSABLE`: P-slices must be disposable, not references.
- `sps->i_poc_type = 0`: Error resilience.
- `sps->b_vui = 0`: `extradata` must not include the VUI.
- `pps->i_chroma_qp_index_offset = 0`: Required for proper color tint.

# Encoding Requirements

- `-bsf:v "filter_units=remove_types=6"`: Device expects no SEI (vendor patched out completely).
- `-profile:v baseline`: Disable unsupported features.
- `-filter:v "transpose=cclock"`: Proper orientation.
- `-pix_fpt:v yuvj420p`: Device prefers full-range pixel format.
- `-b:v 1M`: Target 1 Mbps @ 30 fps (readjust to scale with fps); can do up to 10-20 Mbps.
- `-g:v 1`: I-frames only as disposable P-frames are highly unstable (original vendor uses heuristics to replace P -> I when needed).
- `-sc_threshold:v 0`: Disable scene-cut detection to reduce encoding overhead with GOP length of 1.
- `-c:a pcm_s16le`: Device expects uncompressed signed PCM 16-bit little-endian.
- `-ar:a >= 8 kHz`: Device requires at least 8 Khz audio rate.

# Static Binary

Portable static `ffmpeg` and `ffprobe` exist within [static/](static/).
