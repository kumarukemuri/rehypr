# Rehypr Papirus monochrome fork

Local derivative of https://github.com/PapirusDevelopmentTeam/papirus-icon-theme,
imported from Arch papirus-icon-theme 20260801-1. Original artwork belongs to
Papirus Development Team and contributors; distributed under GPL-3.0 (LICENSE).
Modified for rehypr: ColorScheme-Text foregrounds use the @PRIMARY@ token.
Default blue folder variants also use @PRIMARY@, with @DARK@ for their backs
and @EMBLEM@ for their symbols. Paper inserts and opacity highlights are preserved.

All non-symbolic icons using ColorScheme-Text are included. Semantic accent
colors and other colored artwork are preserved. Symbolic icons already follow the
application text color. The fixed manifest maps icon names and size metadata
to deduplicated SVG templates, including HiDPI aliases. Unmodified size variants
of these names link to the installed Papirus-Dark theme, so large colored icons
are not replaced by scaled-up monochrome icons. Other names inherit Papirus-Dark.

Edit SVG files under templates to customize this local fork. Palette updates
render only the unique templates; aliases and directory metadata are reused.
System files are never modified. Generated files stay outside Git.
