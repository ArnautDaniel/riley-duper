! Copyright (C) 2019 Arnaut Daniel
! See http://factorcode.org/license.txt for BSD license.
USING: alien alien.c-types alien.enums alien.libraries
alien.libraries.finder alien.syntax classes.struct combinators
kernel quotations system vocabs ;
IN: riley-dj
<<
"rileyj" {
    { [ os windows? ] [ "rileyj.dll" ] }
    { [ os macosx? ] [ "librileyj.dylib" ] }
    { [ os unix? ] [ "librileyj.so" ] }
} cond cdecl add-library 

"rileyj" deploy-library
>>

LIBRARY: rileyj

STRUCT: bmp
    { size ulong }
    { width int }
    { height int }
    { buf uchar* } ;

FUNCTION-ALIAS: riley-dj-decode bmp* riley_decode_jpeg ( c-string path )
