# StudyReels CI compatibility shim.
# The studyreels workflow was written against the cactus v2.x layout, where
# this file carried the Android symbol-hiding flag; it seds the flag out
# before building (Dart FFI needs the cactus_* symbols exported). In v1.14
# the flag lived in android/CMakeLists.txt (already removed in this fork),
# so this file exists only to satisfy that CI step and is not referenced
# by any build.
# target_link_options(cactus PRIVATE -Wl,--exclude-libs,ALL)
target_link_options(cactus PRIVATE -Wl,--exclude-libs,ALL)
