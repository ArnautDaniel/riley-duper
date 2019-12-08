! Copyright (C) 2019 Jack Lucas
! See http://factorcode.org/license.txt for BSD license.
USING: kernel math.ranges sequences locals random combinators.random math threads namespaces accessors classes.struct combinators alien.enums io.pathnames io.directories math.parser classes.tuple raylib.ffi raylib.modules.gui prettyprint sequences.deep shuffle assocs math.functions ;

! images.loader.gtk images
! QUALIFIED: images.loader

IN: riley-duper

SYMBOL: textures
SYMBOL: texture-len
SYMBOL: add-button
SYMBOL: save-button
SYMBOL: bg
SYMBOL: loading-screen-max
SYMBOL: loading-vector

TUPLE: world grids last-selected ;
TUPLE: grid x y attributes pictures albums ;
TUPLE: picture name x y attributes ;
TUPLE: album pictures ;

GENERIC: draw ( snark -- )
GENERIC: scroll ( n snark! -- )
GENERIC: update-attribute ( pic attribute name -- )
GENERIC: frame ( pic -- frame )
GENERIC: draw-frame ( pic -- )
GENERIC: clicked ( item -- )
GENERIC: check ( grid -- bool )
GENERIC: increment ( grid -- grid )
GENERIC: reset ( grid -- )
GENERIC: update ( grid -- )
GENERIC: update-picture-coord ( pic grid -- )
GENERIC: render ( world -- )
GENERIC: check-collision ( snark -- )
GENERIC: check-mouse-input ( world -- )
GENERIC: picture-dimensions ( grid -- )
GENERIC: add-pic ( pic grid  -- )
GENERIC: remove-pic ( pic grid -- )
GENERIC: push-ls ( pic world -- )
GENERIC: pop-ls ( world -- )
GENERIC: organize-ls ( pic world -- )
GENERIC: remove-ls ( pic world -- )
GENERIC: find-pic-by-name ( name grid -- pic )
GENERIC: draw-ls ( world -- )
GENERIC: dump-pics ( grid -- )


: <picture> ( name x y -- pic )
    H{ { "selected?" f }
       { "frame-mod" 5 }
       { "frame-size" 110 }
       { "playpen" f }
       { "height" 0 }
       { "width"  0 } } { } assoc-like picture boa clone ;

: make-vector-2 ( x y -- Vector2 )
    Vector2 <struct-boa> ;

: make-rectangle ( x y z n -- Rect )
    Rectangle <struct-boa> ;

: riley-texture ( name -- texture )
    textures get at ;

! Use Factor's gtk jpg loader and send the raw data to
! raylib which can then use it to load the texture
: riley-image-load ( name -- image )
    ! images.loader:load-image
    ! [ bitmap>> ] [ dim>> first ] [ dim>> second ] tri
    ! 4 ! Format number for jpgs
    load-image
    [ load-texture-from-image ] keep
    unload-image ;

M: world find-pic-by-name
    swap name>>
    [ swap name>> = ] curry
    [ last-selected>> ] dip filter first ;

M: world remove-ls
    find-pic-by-name
    world get last-selected>> remove
    world get last-selected<< ;

M: world push-ls
    dup
    [ last-selected>> swap name>> 0 0 <picture> prefix ] dip
    last-selected<< ;

M: world pop-ls
    dup last-selected>> rest
    >>last-selected drop ;

M: world organize-ls
    [ remove-ls ] [ push-ls ] 2bi ;

M: grid check
    [ x>> ]
    [ attributes>> "xinc" of ]
    [ attributes>> "xmax" of ] tri
    [ + ] dip > ;

: increment-y ( grid -- )
    dup [ y>> ] [ attributes>> "yinc" of ] bi
    + >>y drop ;

: increment-x ( grid -- )
    dup [ x>> ] [ attributes>> "xinc" of ] bi
    + >>x drop ;

: reset-x ( grid -- grid )
    dup  attributes>> "xset" of >>x ;

M: grid increment
    dup check
    [ [ increment-y ]
      [ reset-x ] bi ]
    [ dup increment-x ] if ;

M: grid reset
    dup attributes>> "xset" of >>x
    dup attributes>> "yset" of >>y drop ;

M: grid picture-dimensions
    { [ pictures>> ]
      [ attributes>> "picheight" of
        [ "width" pick update-attribute ] curry ]
      [ attributes>> "picwidth" of
        [ "height" pick update-attribute ] curry ]
      [ attributes>> "playpen" of
        [ "playpen" pick update-attribute ] curry ] }
    cleave
    [ map ] 2dip [ map ] dip map drop ;

M: grid draw
    pictures>> [ draw ] each ;

M: picture update-picture-coord
    [ [ x>> ] [ y>> ] bi ] dip
    dup [ y<< ] dip x<< ;

M: grid update
    dup [ pictures>> ]
    [ [ swap over swap update-picture-coord increment drop ] curry ]
    bi each [ reset ] [ picture-dimensions ] bi ;

M: world update
    grids>> values [ update ] each ;

M: picture frame
    [ x>> ] [ y>> ] [ attributes>> ] tri
    [ "width" of ] [ "height" of ] bi
    make-rectangle ;

: draw-frame-if-selected ( pic -- )
    dup attributes>> "selected?" of
    [ draw-frame ] [ drop ] if ;

M: picture draw-frame
    dup attributes>> "selected?" of
    [ [ dup [ x>> ] dip
        attributes>> "frame-mod" of - ]
      [ dup [ y>> ] dip
        attributes>> "frame-mod" of - ]
      [ attributes>> "frame-size" of dup ]
      tri RED draw-rectangle ]
    [ drop ] if ;

M: picture update-attribute
    attributes>> set-at ;

! Admittently a bit complex.  Should factor probably.
M: picture draw
    {
        [ draw-frame-if-selected ]
        [ name>> riley-texture ] [ x>> ] [ y>> ]
        [ attributes>> "width" of ]
        [ attributes>> "height" of ]
    } cleave make-rectangle

    [ dup [ width>> ] [ height>> ] bi
      0 0 2swap make-rectangle ] dip
    0 0 make-vector-2 0 WHITE draw-texture-pro ;


M: world draw-ls
    last-selected>>
    dup empty?
    [ drop ] [
        first name>> riley-texture
        dup [ width>> ] [ height>> ] bi
        0 0 2swap make-rectangle 
        770 400 400 320 make-rectangle
        0 0 make-vector-2 0 WHITE draw-texture-pro ] if ;

M: grid find-pic-by-name
    swap name>>
    [ swap name>> = ] curry
    [ pictures>> ] dip
    filter first ;

M: grid remove-pic
    dup [ find-pic-by-name ] dip
    dup [ pictures>> remove ] dip
    pictures<< ;

M: grid add-pic
    swap [ dup pictures>> ] dip
    name>> 0 0 <picture> clone prefix
    >>pictures drop ;

: make-window ( -- )
    1200 800 "Riley Duper" init-window
    30 set-target-fps ;

: get-pictures ( -- seq )
    current-directory get directory-files
    [ file-extension "png" = ] filter
    [ 0 3 rot subseq "___" = ] reject dup
    length loading-screen-max set ;

: get-mouse-frame ( -- frame )
    get-mouse-x
    get-mouse-y
    1 1 make-rectangle ;

: unclick-from-ls ( pic -- )
    name>> [ swap name>> = ] curry
    world get last-selected>> swap
    reject world get last-selected<< ;

: unclick-from-playpen ( pic -- )
    world get grids>> "playpen" of
    remove-pic ;

: unclick ( pic -- )
    [ unclick-from-ls ]
    [ unclick-from-playpen ] bi ;

: playpen-ls-update ( pic -- )
    world get organize-ls ;

: main-ls-change ( pic -- )
    [ world get push-ls ]
    [ world get grids>> "playpen" of add-pic ] bi ;

: main-ls-update ( pic -- )
    dup attributes>> "selected?" of
    [ main-ls-change ]
    [ unclick ] if ;

: update-ls ( pic -- )
    dup attributes>> "playpen" of
    [ playpen-ls-update ]
    [ main-ls-update ] if ;

M: picture clicked
    dup attributes>> "selected?" of not
    "selected?" pick update-attribute
    update-ls ;

M: picture check-collision
    dup frame get-mouse-frame check-collision-recs
    [ clicked ] [ drop ] if ;

M: grid check-collision
    pictures>> [ check-collision ] each ;

: <album> ( pictures -- album )
    album boa ;

: add-album-thumbnail ( quereel -- )
    dup albums>> first pictures>> first
    [ dup pictures>> ] dip prefix
    >>pictures drop ;

: add-album ( quereel album -- )
    [ dup albums>> ] dip prefix
    >>albums add-album-thumbnail ;

: playpen-to-quereel ( world -- )
    grids>> [ "quereel" of ] [ "playpen" of ] bi
    pictures>> <album> add-album ;

M: grid dump-pics
    { } >>pictures drop ;

: clear-tetriary-grids ( world -- )
    [ { } >>last-selected drop ]
    [ grids>> "playpen" of dump-pics ] bi ;

:: sift-grid ( grid1 grid2 -- )
    grid1 pictures>>
    grid2 albums>> first pictures>>
    [ name>> ] map
    [ swap name>> swap member? ] curry reject
    grid1 pictures<< ;

: sift-main-grid ( world -- )
    grids>> [ "main" of ] [ "quereel" of ] bi
    sift-grid ;

! This actually seems to work fairly well
: ok-clicked ( world -- )
    ! All images from the playpen need to go into a
    ! quereel album
    [ playpen-to-quereel ]
    ! Playpen and last selected need to be cleared
    [ clear-tetriary-grids ]
    ! Images going into the quereel are removed from
    ! the main grid
    [ sift-main-grid ] tri ;

: mouse-collision ( z x y c -- bool )
    make-rectangle get-mouse-frame check-collision-recs ;

: copy-new-pic-from-album ( pic n y -- )
    [ number>string ] bi@ swap "-" prepend
    append "___" prepend ".jpg" append
    [ name>> ] dip copy-file ;

: copy-new-album-name ( n pic -- )
    pictures>> dup length <iota>
    [ [ copy-new-pic-from-album ] curry ] 2dip
    rot
    2each ;

: copy-new-pic-name ( n pic -- )
    name>> swap number>string
    "___" prepend
    ".jpg" append
    copy-file ;

: copy-new-file-name ( pic n -- )
    swap dup album?
    [ copy-new-album-name ]
    [ copy-new-pic-name ] if ;

! Dangerous
: remove-old ( -- )
    current-directory get directory-files
    [ file-extension "jpg" = ] filter
    [ 0 3 rot subseq "___" = ] filter
    [ delete-file ] each ;

: save-clicked ( world -- )
    ! Gather main and quereel images into a sequence
    ! Run a 2 map with an <iota> of the length
    ! Rename files
    remove-old
    grids>> [ "main" of pictures>> ]
    [ "quereel" of albums>> ] bi append
    dup length <iota>
    [ copy-new-file-name ] 2each ;
    
: check-button-collision ( world -- )
    { { [ dup last-selected>> empty? not
          800 725 150 25 mouse-collision
          and ] [ ok-clicked ] }
      { [ 975 725 150 25 mouse-collision ]
        [ save-clicked ] }
      [ drop ] } cond ;

! Reject quereel from clicks for now.
! Should be right clicked only
M: world check-collision 
    dup grids>> [ first "quereel" = ] reject
    values [ check-collision ] each
    check-button-collision ;

M: world draw
    [ grids>> values [ draw ] each ]
    [ draw-ls ] bi ;

M: world check-mouse-input
    dup 0 is-mouse-button-pressed
    [ check-collision ] [ drop ] if
    get-mouse-wheel-move dup 0 = not
    [ swap grids>> "main" of scroll ] [ 2drop ] if ;

: draw-overlay ( -- )
    75 100 2 650 make-rectangle 12.0 12 2
    RAYWHITE draw-rectangle-rounded-lines
    740 100 2 650 make-rectangle 12.0 12 2
    RAYWHITE draw-rectangle-rounded-lines 
    900 390 150 2 make-rectangle 12.0 12 2
    RAYWHITE draw-rectangle-rounded-lines ;

: draw-buttons ( -- )
    add-button get 800 725 WHITE draw-texture
    save-button get 975 725 WHITE draw-texture ;

: draw-bg ( -- )
    bg get 0 0 WHITE draw-texture ;

M:: grid scroll ( n snark! -- )
    snark
    [ attributes>> "factorinc" of n * ]
    [ attributes>> "yset" of ] bi +
    "yset" snark attributes>> set-at ;
    
M: world render
    begin-drawing
    draw-bg
    draw
    draw-overlay
    draw-buttons
    end-drawing ;

: make-initial-world ( -- world )
    H{ { "playpen" T{ grid { x 760 } { y 30 }
                      { attributes { { "xinc" 110 }
                                     { "xmax" 1100 }
                                     { "yinc" 110 }
                                     { "xset" 760 }
                                     { "picwidth" 100 }
                                     { "picheight" 100 }
                                     { "nextgrid" "quereel" }
                                     { "playpen" t }
                                     { "yset" 30 } } }
                      { pictures { } } { albums { } } } }
       { "main" T{ grid { x 100 } { y 0 }
                   { attributes { { "xinc" 210 }
                                  { "xmax" 600 }
                                  { "yinc" 210 }
                                  { "xset" 100 }
                                  { "yset" 30  }
                                  { "picwidth" 200 }
                                  { "picheight" 200 }
                                  { "nextgrid" "playpen" }
                                  { "factor" 0 }
                                  { "factorinc" 60 } } }
                   { pictures { } } { albums { } } } }
       { "quereel" T{ grid { x 10 } { y 50 }
                      { attributes { { "xinc" 60 }
                                     { "xmax" 60 }
                                     { "yinc" 60 }
                                     { "xset" 10 }
                                     { "yset" 50  }
                                     { "picwidth" 50 }
                                     { "picheight" 50 }
                                     { "nextgrid" "null" } } }
                      { pictures { } } { albums { } } } } 
    } { } assoc-like
    { }  world boa clone ;

: progress-string ( -- str )
    texture-len get number>string
    "/" loading-screen-max get number>string
    append append ;

: loading-circle ( -- start end )
    360 loading-screen-max get /
    texture-len get * -1 * floor
    0 swap ;

: draw-loading-screen ( -- )
    begin-drawing
    draw-bg
    "Loading Pictures" 500 400 24 BLACK draw-text
    progress-string 750 400 24 BLACK draw-text
    loading-vector get
    100 loading-circle 100 RED draw-circle-sector
    end-drawing ;

! Japanese beer is nice
: set-pictures ( -- )
    get-pictures ! [ draw-loading-screen ]
    [ dup riley-image-load { } 2sequence
      textures get swap prefix textures set
    texture-len inc ]
    each ;

: button-loader ( name -- button )
    load-image dup 150 25 image-resize
    [ load-texture-from-image ] keep
    unload-image ;

: set-buttons ( -- )
    "add.png" button-loader
    add-button set
    "save.png" button-loader
    save-button set ;

: set-bg ( -- )
    "Shore.png" load-image [ load-texture-from-image ] keep
    unload-image bg set ;

: populate-world ( world -- world )
    get-pictures
    [ 0 0 <picture> ]
    map swap dup 
    [ grids>> "main" of swap >>pictures
      picture-dimensions ] dip
    dup world set ;

: init-setup ( -- world )
    make-window
    { } textures set
    0 texture-len set
    600 600 Vector2 <struct-boa> loading-vector set
    set-bg set-buttons
    make-initial-world
    set-pictures
    populate-world ;

: main ( -- )
    init-setup
    [ dup [ update ] [ render ] [ check-mouse-input ] tri
      window-should-close not ]
    loop close-window drop ;

MAIN: main
