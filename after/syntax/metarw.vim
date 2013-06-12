syntax match metarwLocalDirectoryish /^\%>2l[^/]*\/\?\ze\s/
syntax match metarwLocalDate /\%>2l\s\+\zs\d\{2}\/\d\{2}\/\d\{2}\s\d\{2}:\d\{2}:\d\{2}/
syntax match metarwLocalSize /\%>2l\s\zs\d\+\ze\s/
syntax match metarwLocalPermission /\%>2l[rwx-]\{9}$/


highlight default link metarwLocalDirectoryish Directory
highlight default link metarwLocalDate NonText
highlight default link metarwLocalSize NonText
highlight default link metarwLocalPermission NonText
