sed -i \
  -e '/dlfcn.h/a #ifndef RTLD_DEEPBIND'  \
  -e '/dlfcn.h/a #define RTLD_DEEPBIND 0'  \
  -e '/dlfcn.h/a #endif'  \
  shared/nm-glib-aux/nm-json-aux.c
