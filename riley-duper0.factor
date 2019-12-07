! Copyright (C) 2019 Jack Lucas
! See http://factorcode.org/license.txt for BSD license.
USING: kernel math.ranges sequences locals random combinators.random math threads namespaces accessors classes.struct combinators alien.enums io.pathnames io.directories math.parser classes.tuple raylib.ffi raylib.modules.gui prettyprint images images.loader.gtk concurrency.combinators sequences.deep shuffle ;

QUALIFIED: images.loader

IN: riley-duper3

SYMBOL: grid-x
SYMBOL: grid-y
SYMBOL: mouse
SYMBOL: grid-factor
SYMBOL: selected
SYMBOL: last-selected
SYMBOL: pictures
SYMBOL: background
SYMBOL: ok-button
SYMBOL: cancel-button
! Absolutely disgusting
SYMBOL: playpeni
SYMBOL: quereel
SYMBOL: playpen-x
SYMBOL: playpen-y
SYMBOL: playpen-max
SYMBOL: quereel-max
SYMBOL: quereel-x
SYMBOL: quereel-y

TUPLE: picture name image x y selected? ;

! If anyone ever sees this I'll probably commit sodoku out of shame
TUPLE: playpen name image x y selected? ;
TUPLE: que-pen name image x y playpen ;

GENERIC: draw ( snark -- )
GENERIC: update-picture-coord ( pic -- pic )
GENERIC: frame ( pic -- frame )
GENERIC: draw-frame ( pic -- pic )
GENERIC: clicked ( item -- )

: make-vector-2 ( x y -- Vector2 )
    Vector2 <struct-boa> ;

: just-load ( name -- image )
    images.loader:load-image
    [ bitmap>> ] [ dim>> first ] [ dim>> second ] tri 4
    load-image-pro load-texture-from-image ;

: make-rectangle ( x y z n -- Rect )
    Rectangle <struct-boa> ;

M: playpen draw-frame
    dup selected?>>
    [ dup dup
      x>> 5 - swap 
      y>> 5 -
      115 115
      ORANGE draw-rectangle ]
    [ ] if ;

M: playpen frame
    dup x>> swap y>>
    100 100 make-rectangle ;

M: playpen update-picture-coord
    playpen-x get >>x
    playpen-y get >>y ;

M: playpen draw
    [ image>> ] [ x>> ] [ y>> ] tri
    100 100 make-rectangle
    [ dup [ width>> ] [ height>> ] bi
      0 0 2swap make-rectangle ] dip 
    0 0 make-vector-2 0 WHITE draw-texture-pro ;


: <picture> ( name image x y selected? -- pic )
    picture boa ;

: <playpen> ( name image x y selected? -- pic )
    playpen boa ;

M: que-pen update-picture-coord
    quereel-x get >>x
    quereel-y get >>y ;

M: que-pen draw
    [ image>> ] [ x>> ] [ y>> ] tri
    WHITE draw-texture ;

: <que-pen> ( name image x y playpen -- quepen )
    que-pen boa ;

: make-window ( -- )
    1200 800 "Riley Duper" init-window
    30 set-target-fps ;

: riley-background ( -- )
    RAYWHITE clear-background ;

: get-pictures ( -- seq )
    current-directory get directory-files
    [ file-extension "jpg" = ] filter ;

: check-quereel ( -- bool )
    quereel-x get 50 + 55 > dup
    [ 10 quereel-x set
      quereel-y get 70 + quereel-y set ]
    when ;

: increment-quereel ( -- )
    check-quereel
    [ ] [ quereel-x get 50 + quereel-x set ] if ;

: reset-quereel ( -- )
    10 quereel-x set
    30 quereel-y set ;

: setup-quereel ( -- )
    reset-quereel
    400 quereel-max set ;

: check-playpen ( -- bool )
    playpen-x get 100 + 1100 > dup
    [ 760 playpen-x set
      playpen-y get 110 + playpen-y set ]
    when ;

: increment-playpen ( -- )
    check-playpen
    [ ] [ playpen-x get 110 + playpen-x set ] if ;

: reset-playpen ( -- )
    760 playpen-x set
    30 playpen-y set ;

: setup-playpen ( -- )
    reset-playpen
    400 playpen-max set ;

: reset-grid ( -- )
    100 grid-x set
    grid-factor get grid-y set ;

: setup-grid ( -- )
    0 grid-factor set
    reset-grid ;

: check-increment ( -- bool )
    grid-x get 200 + 700 > dup
    [ 100 grid-x set
      grid-y get 210 + grid-y set ]
    when ;

: increment-grid ( -- )
    check-increment
    [ ] [ grid-x get 210 + grid-x set ] if ;

: shuffle-last-selected ( pic -- )
    name>> [ swap name>> = ] curry
    last-selected get swap
    filter first dup
    last-selected get
    remove swap prefix last-selected set ;

M: picture draw-frame
    dup selected?>>
    [ dup dup
      x>> 5 - swap 
      y>> 5 -
      210 210
      RED draw-rectangle ]
    [ ] if ;

M: picture frame
    dup x>> swap y>>
    200 200 make-rectangle ;

M: playpen clicked
    shuffle-last-selected ;

: get-mouse-frame ( -- frame )
    get-mouse-x
    get-mouse-y
    1 1 make-rectangle ;

: push-playpen ( name -- )
    dup just-load 0 0 f <playpen>
    playpeni get swap prefix playpeni set ;

: pop-playpen ( item -- )
    name>> [ swap name>> = ] curry
    playpeni get swap
    reject playpeni set ;

: pop-last-selected ( item -- )
    dup pop-playpen
    name>> [ swap name>> = ] curry
    last-selected get swap
    reject last-selected set  ;

: push-last-selected ( item -- )
    last-selected get swap
    name>> dup push-playpen
    dup just-load
    800 410 f <picture>
    prefix last-selected set ;

M: picture clicked
    dup selected?>>
    [ f swap dup  pop-last-selected selected?<< ]
    [ t swap dup push-last-selected selected?<< ] if ;

: draw-last-selected ( -- )
    last-selected get dup empty?
    [ drop ]
    [ first [ image>> ] [ x>> ] [ y>> ] tri
    350 350 make-rectangle
    [ dup [ width>> ] [ height>> ] bi
      0 0 2swap make-rectangle ] dip 
    0 0 make-vector-2 0 WHITE draw-texture-pro 
    ] if ;

: picture-frames ( -- )
    pictures get
    [ dup frame get-mouse-frame check-collision-recs
      [ clicked ] [ drop ] if ]
    each
    playpeni get
    [ dup frame get-mouse-frame check-collision-recs
      [ clicked ] [ drop ] if ]
    each ;

: make-quepen  ( name -- name image )
    dup just-load ;

: make-quereel ( -- que-pen )
    playpeni get first name>> make-quepen
    0 0 playpeni get <que-pen> ;

: reset-from-que ( -- )
    { } playpeni set
    { } last-selected set ;

: remove-quereel-pics ( -- )
    quereel get first playpen>>
    [ name>> ] map
    [ swap name>> swap member? ] curry
    pictures get swap reject
    pictures set ;

: ok-clicked ( -- )
    playpeni get length 1 >=
    [ make-quereel
      quereel get swap prefix
      quereel set reset-from-que remove-quereel-pics ]
    [ ] if ;

: numeric-rename ( n len -- seq )
    dup [ swap number>string <repetition> ] dip
    1 swap [a,b]
    [ number>string "-" swap append append ".jpg" append ]
    2map ;

: generate-renames-playpen ( playpen n -- )
    [ playpen>> [ name>> ] map ] dip
    over length numeric-rename
    [ move-file ] 2each ;

: generate-renames-playpeni ( playpeni -- n )
    dup length swap over 1 swap [a,b]
    [ generate-renames-playpen ] 2each ;

: generate-renames-pictures ( n pictures -- )
    dup length swap
    [ over +
      (a,b] [ number>string ".jpg" append ] map ] dip
    [ name>> ] map
    swap [ move-file ] 2each ;

: generate-renames ( playpeni pictures --  )
    [ generate-renames-playpeni ] dip
    generate-renames-pictures ;

: save-clicked ( -- )
    quereel get
    pictures get
    generate-renames
    ;

: button-frames ( -- )
    800 775 150 50 make-rectangle
    get-mouse-frame check-collision-recs
    [ ok-clicked ] [ ] if
    1000 775 150 50 make-rectangle
    get-mouse-frame check-collision-recs
    [ save-clicked ] [ ] if ;

M: picture update-picture-coord
    grid-x get >>x
    grid-y get >>y ;

M: picture draw
    [ image>> ] [ x>> ] [ y>> ] tri
    200 200 make-rectangle
    [ dup [ width>> ] [ height>> ] bi
      0 0 2swap make-rectangle ] dip 
    0 0 make-vector-2 0 WHITE draw-texture-pro ;

: draw-playpen ( -- )
    playpeni get
    [ update-picture-coord
      draw-frame draw increment-playpen ] each
    reset-playpen ;

: draw-quereel ( -- )
    quereel get
    [ update-picture-coord
      draw increment-quereel ] each
    reset-quereel ;

: draw-pictures ( -- )
    pictures get
    [ update-picture-coord
      draw-frame draw increment-grid ] each
    reset-grid ;

: setup-pictures ( -- )
    [ get-pictures
      [ dup just-load
        f f f <picture> pictures get swap prefix pictures set ]
      each ] "pic" spawn drop ;

: check-mouse-input ( -- )
    0 is-mouse-button-pressed
    [ picture-frames button-frames ] [ ] if ;

: grid-factor-update ( x -- )
    dup 0 = not
    [
        -1 = 
        [ grid-factor get 60 + grid-factor set
          grid-factor get grid-y set ]
        [ grid-factor get 60 - grid-factor set
          grid-factor get grid-y set ] if
    ] [ drop ] if ;

: update-mouse ( -- )
    get-mouse-wheel-move dup number>string mouse set
    grid-factor-update ;

: draw-overlay ( -- )
    75 100 2 650 make-rectangle 12.0 12 2 RAYWHITE draw-rectangle-rounded-lines
    740 100 2 650 make-rectangle 12.0 12 2 RAYWHITE draw-rectangle-rounded-lines 
    900 390 150 2 make-rectangle 12.0 12 2 RAYWHITE draw-rectangle-rounded-lines ;

: draw-buttons ( -- )
    ok-button get 800 775 WHITE draw-texture
    cancel-button get 1000 775 WHITE draw-texture ;

: render-loop ( -- )
    begin-drawing
    riley-background
    draw-pictures
    draw-playpen
    draw-quereel
    draw-last-selected
    draw-overlay
    ! draw-buttons
    end-drawing ;

: setup-buttons ( -- )
    "bak/ok.png" load-image dup
    150 50 image-resize
    load-texture-from-image
    ok-button set
    "bak/cancel.png" load-image dup
    150 50 image-resize
    load-texture-from-image
    cancel-button set ;


: setup-last-selected ( -- )
    { } last-selected set ;

: setup-background ( -- )
    "bak/bg.png" load-image dup
    1400 1400 image-resize
    load-texture-from-image
    background set ;

: setup ( -- )
    { } playpeni set
    { } quereel set
    { } pictures set
    ! setup-background
    setup-pictures
    setup-grid
    setup-playpen
    setup-quereel
    setup-last-selected ;

: main ( -- )
    make-window setup riley-background update-mouse
    [ yield render-loop update-mouse check-mouse-input
      window-should-close not ]
    loop close-window ;

MAIN: main
