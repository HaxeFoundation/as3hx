# Fix copyright dates to 2013
s,Copyright [0-9]{4} TiVo,Copyright 2013 TiVo,g

# convert test_only namespace to a compile time flag requirement.
# - remove namespace import
s,import com.tivo.core.util.test_only;,,g
# - convert declarations to flag and make public
s,(^[	 ]*)test_only ,\1//UNCOMMENT@:require(TIVOCONFIG_TEST)\
\1public ,g
# - remove namespace qualifier on reference
s,test_only::,,g
# - remove use namespace lines
s,use namespace test_only;,,g

# convert test_overridable to metadata
# - remove namespace import
s,import com.tivo.core.util.test_overridable;,,g
# - convert declarations to metadata and make private
s,(^[	 ]*)test_overridable ,\1//UNCOMMENT@test_overridable\
\1private ,g
# - remove namespace qualifier on reference
s,test_overridable::,,g
# - remove use namespace lines
s,use namespace test_overridable;,,g

# remove comments around "custom" Dictionary templating
s,Dictionary/\*\.<([^*]+)\*/,Dictionary.<\1,g

# remove 'static' tag on [BeforeClass] and [AfterClass] marked test methods
/^[	  ]*\[(Before|After)Class.*\]$/{
    $!{ N
        s,(^[	 ]*)\[(Before|After)Class(.*)\]\n([	 ]*)(public static |static public ),\1[\2Class\3\]\
\4public ,g
	t sub-yes
	P
	D
	:sub-yes
    }
}

# replace all imports of org.flexunit.asserts.* with
# massive.munit.Assert
s,import org\.flexunit\.asserts\..*;$,import massive.munit.Assert;,g

# remove all imports of org.hamcrest.*, as they are accessible (for now)
# via BaseTest inheritance
s,import org\.hamcrest\..*$,,g

# replace imports of org.flexunit.async.Async with 
# massive.munit.Async
s,import org\.flexunit\.async\.Async;$,import massive.munit.Async;,g

# remove all other imports of org.flexunit.*
s,import org\.flexunit\..*$,,g

# Fix up new Date() constructors...
#s,new Date\(\),Date.now(),g
