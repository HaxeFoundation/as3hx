s,//UNCOMMENT,,g
s,#if TIVOCONFIG_ASSERT,,g
s,#end // TIVOCONFIG_ASSERT,,g
s,#if TIVOCONFIG_DEBUG_PRINT,,g
s,#end // TIVOCONFIG_DEBUG_PRINT,,g

# Fix up class name fetching...
s,Type\.getClassName(\([^\)]*\)),Type.getClassName(Type.getClass(\1)),g

# Remove spurious semicolons in the left column...
#/^;$/d
