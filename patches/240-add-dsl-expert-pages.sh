[ "$FREETZ_PATCH_DSL_EXPERT" == "y" ] || return 0
echo1 "adding dsl expert pages"
for file in \
	${FILESYSTEM_MOD_DIR}/usr/www/avm/html/de/internet/adsl.html \
	${FILESYSTEM_MOD_DIR}/usr/www/avm/html/de/internet/bits.html \
	${FILESYSTEM_MOD_DIR}/usr/www/avm/html/de/internet/atm.html \
	${FILESYSTEM_MOD_DIR}/usr/www/avm/html/de/internet/overview.html \
	${FILESYSTEM_MOD_DIR}/usr/www/avm/html/de/internet/feedback.html \
	; do
	if [ -f "$file" ]; then
		modsed "
		s|query box:settings.expertmode.activated ?>. .1.|query box:settings/expertmode/activated ?>' '0'|
		" "$file"
		modsed "
/query box:settings.expertmode.activated ?>. .0./i \
<? if eq '<? query box:settings\/expertmode\/activated ?>' '1' \`\n\
<li><a href=\"javascript:uiDoLaborDSLPage()\">Einstellungen<\/a><\/li>\n\
\` ?>\
" "$file"
		echo2 "patching $file"
	fi
done
if isFreetzType 7240 7270; then
	modpatch "$FILESYSTEM_MOD_DIR" "${PATCHES_DIR}/cond/de/dsl-expert-pages_7270.patch"
else
	modpatch "$FILESYSTEM_MOD_DIR" "${PATCHES_DIR}/cond/de/dsl-expert-pages_7170.patch"
fi
