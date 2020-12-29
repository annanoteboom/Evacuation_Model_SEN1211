__includes [ "utilities.nls" ] ; all the boring but important stuff not related to content

breed [visitors visitor]
breed [staff staffmember]

turtles-own [
  destination
  current-patch-color
  key-patch
  ;previous-patch
  gender
  very-old-or-young
  runningspeed
  walkingspeed
  people-near-me
  kid-parent
  done?
  patches-in-sight
  search-step?
  task-delay
]

globals [
  p-valids ; patches where one can walk
  all-colors
  turtles-safe
  emergency ;has the alarm gone off
  alarmtime
]

patches-own [
  dijkstra-dist
]

to setup
  clear-all
  setupMap
  ;place visitors and staff randomly on valid patches
  ask n-of population_visitors patches with [pcolor = 9.9 or pcolor = 137.1 or pcolor = 106.5 or pcolor = 35.6 or pcolor = 118.1 or pcolor = 44.9 or pcolor = 44.3 or pcolor = 12.6 or pcolor = 125.7 or pcolor = 63.6 or pcolor = 14.8 or pcolor = 87] [sprout-visitors 1[ set color green ;- 2 + random 7  ;; random shades look nice
    set size 10]]  ;; easier to see]]
  ask n-of population_staff patches with [pcolor = 9.9 or pcolor = 63.6 or pcolor = 25.6 or pcolor = 84.5 or pcolor = 14.8 or pcolor = 28.7 or pcolor = 87 or pcolor = 72.1] [sprout-staff 1[ set color red ;- 2 + random 7  ;; random shades look nice
    set size 10]]  ;; easier to see]]
  ask turtles [choose-destination set key-patch patch 0 0]
  ask turtles [set gender one-of ["male" "female"]] ;assumption: distribution male/female is 50% even though it is Delft
  ask turtles [set very-old-or-young random 100] ;assumption: 10% of people in the library are very old/young and therefore walk slower
  ask turtles [ifelse very-old-or-young < Percentage-kids or very-old-or-young > (100 - Percentage-old-people) [set runningspeed 0.6] [ifelse gender = "male" [set runningspeed 1] [set runningspeed 0.93]]] ; 15% of the population walks slowly due to age, women walk a little slower than men
  ask turtles [ifelse very-old-or-young < Percentage-kids or very-old-or-young > (100 - Percentage-old-people) [set walkingspeed 0.3] [ifelse gender = "male" [set walkingspeed 0.6667] [set walkingspeed 0.6]]] ; 15% of the population walks slowly due to age, women walk a little slower than men
  ; give all kiddo turtles a designated parent
  ask turtles [set kid-parent nobody]
  ask turtles [set task-delay 0]
  ask turtles [if (very-old-or-young < Percentage-kids)  [
    update-people-closeby 10
    set color yellow - 2
    ;check if there is someone in your direct surroundings you can make your parent
    ifelse one-of turtles with [member? [who] of self [people-near-me] of myself and kid-parent = nobody and very-old-or-young > Percentage-kids] != nobody [
      set kid-parent [who] of min-one-of turtles with [member? [who] of self [people-near-me] of myself and kid-parent = nobody and very-old-or-young > Percentage-kids] [distance myself]
      ask min-one-of turtles with [member? [who] of self [people-near-me] of myself and kid-parent = nobody and very-old-or-young > Percentage-kids] [distance myself] [
        set kid-parent [who] of myself set color blue set search-step? true] ]
    ; otherwise stop being a child
    [set very-old-or-young (Percentage-kids + 1) ifelse gender = "male" [set runningspeed 1] [set runningspeed 0.93] ifelse gender = "male" [set walkingspeed 0.6667] [set walkingspeed 0.6]] ]]
  set emergency "no"
  set alarmtime "noalarm"
  reset-ticks
end

to choose-destination
  ifelse pycor < 28.7 and ([pcolor] of patch-here = 25.6 or [pcolor] of patch-here = 28.7) [
    set destination one-of patches with [pcolor = 14.8 and pxcor > 10 and pxcor < 30]] [
    set destination one-of patches with [pcolor = 14.8 and pxcor > 110 and pxcor < 130]]
end

to go
  ask turtles [set current-patch-color [pcolor] of patch-here]
                      ; first three minutes everybody just walks randomly, then the alarm goes off
                      ;ifelse ticks < 30 [ask turtles [walk-randomly]] [ask turtles [walk-out]]
  ;if the automatic_emergency is turned on after 30 seconds the alarm goes off
  if automatic_emergency = true [if ticks = 30 [alarm]]

  ifelse emergency = "no" [ask turtles [walk-randomly]] [ask turtles [walk-out]
    if (ticks - alarmtime) > 600 [write "it is taking too long," write count turtles print " people still in the building are dead now" stop]]

;  ifelse automatic_emergency = true
    ;if the automatic_emergency is turned on after 30 seconds the alarm goes off
;    [ifelse ticks < 30 [ask turtles [walk-randomly]] [ask turtles [walk-out]]
;      if (ticks - 30) > 400 [write "it is taking too long," write count turtles print " people still in the building are dead now" stop]]
    ; once the alarm button has been pressed, the emergency situation commences
;    [ifelse emergency = "no" [ask turtles [walk-randomly]] [ask turtles [walk-out]
;    if (ticks - alarmtime) > 600 [write "it is taking too long," write count turtles print " people still in the building are dead now" stop]]]
  if not any? turtles [ print "everyone got evacuated safely" stop ]

  tick ; next time step
end

to walk-randomly
  (ifelse
  ; when you are accidentally in a wall on a staircase or in pink furniture or in the middle of the balie
  current-patch-color = 0 or current-patch-color = 4.5 or current-patch-color = 125.8 [rt 150 fd 2]
  ; at an exit or already in the outsie brown somehow
  current-patch-color = 14.8 or current-patch-color = 44.6 or current-patch-color = 34.3 [set turtles-safe (turtles-safe + 1) die
      if kid-parent != nobody [ask one-of turtles with [kid-parent = [who] of myself ][die]]]
    [rt (random 100 - 50) check-for-walls check-for-crowdwalk])
end

to alarm
  set emergency "yes"
  set alarmtime ticks
  ask turtles [check-for-task]
  ask staff [pick-destination]
  if experiment = "nearest exit" [ask turtles [pick-destination]]
  if experiment = "everyone to same exit" [
    if same_exit = "above right exit"[ask turtles [set destination patch 155 170]]
    if same_exit = "main exit" [ask turtles [set destination patch 125 146]]
    if same_exit = "below left exit" [ask turtles [set destination patch 23 30]]]
end

to pick-destination
  let a [ distance patch 23 30 ] of patch-here ; linksonder
  let b [ distance patch 115 149 ] of patch-here ; linker hoofduitgang
  let c [ distance patch 125 146 ] of patch-here ; rechter hoofduitgang
  let d [ distance patch 155 170 ] of patch-here ; rechtsboven
  if min (list a b c d) = a [set destination patch 23 30]
  if min (list a b c d) = b [set destination patch 115 149]
  if min (list a b c d) = c [set destination patch 125 146]
  if min (list a b c d) = d [
    ifelse current-patch-color = 9.9 [set destination patch 125 146] [set destination patch 155 170]]
end

to check-for-task
  ;assign a task when the alarm has gone off
  if current-patch-color = 63.6 [set task-delay (random-poisson 60)]  ;toilet
  ;hier kunnen we nog heel veel taken aan toevoegen
end


to parents-seek-kids
  set done? false
  ; parents go to their kids and pick them up, afterwards, they go to the exit
  if kid-parent != nobody [
  if very-old-or-young >= Percentage-kids and turtle kid-parent != nobody [
      ; if you are practically next to your kid or walking with it, pick it up (have it always be on your patch)
    ifelse distance (turtle kid-parent) <= 1.5 [ask turtle kid-parent [move-to myself] ] [
        ; if not, search your visible surrounding
        if search-step? [update-people-closeby (distance turtle kid-parent) set search-step? false]
        ; if you can see your kid, face it and walk to it
      (ifelse (member? kid-parent people-near-me) [face turtle kid-parent check-for-walls check-for-crowd]
          ; if you can't see your kid but you can see a door that is closer to your kid, walk to it
          any? patches-in-sight with [pcolor = 84.5] and current-patch-color != 84.5 [
            face min-one-of patches with [(member? self [patches-in-sight] of myself) and pcolor = 84.5] [distance (turtle [kid-parent] of myself)]
            check-for-walls check-for-crowd]
          ; if you can't see your kid and you cant see a door, walk around randomly in the hopes of finding either
          [walk-randomly set search-step? true] )
        ; if you are now in a doorway, go scan your surrounding again next step
        if current-patch-color = 84.5 [set search-step? true check-for-walls check-for-crowd]
   set done? true
  ]]]
  ; kids walk around randomly until their parents pick them up
  if very-old-or-young < Percentage-kids and turtle kid-parent != nobody [if distance turtle kid-parent > 1 [
    walk-randomly set done? true]]
end


to walk-out

  parents-seek-kids
  if not done? [

  ifelse task-delay != 0 [set task-delay task-delay - 1]
  [
  (ifelse

  ;; common spaces
  ; main hall

    current-patch-color = 9.9 [
      ; If you are in the down left corner and want to go to the downleft exit
      (ifelse pxcor < 36 and pycor > 32.9 and ([pxcor] of [destination] of self < 30) [face patch 38 31]
        ; if you are in the down left corner and want to go to the main entrance, dont do it, just go to the exit in front of you nose dumbass
      pycor < 35 and ([pxcor] of [destination] of self > 30) [set destination one-of patches with [pcolor = 14.8 and pxcor > 10 and pxcor < 30]]
        ; if you are in the corner above and right of the main exit behind the wall
      pycor < 145 and pycor > 141 and pxcor < 137 and pxcor > 128 [face patch 125 142]
      pycor > 142 and pxcor > 128 and pxcor < 140 [face patch 138 141]
        ; if you are along side the wall of the dark yellow chamber
      pycor <= 126 and pycor >= 115 and pxcor >= 123 and pxcor <= 150 [face patch 120 124]
       ; if you are around the help desk and cant get round
      pycor > 88 and pycor < 98 and pxcor <= 92 and pxcor > 85 [face patch 82 103]
      pycor > 88 and pycor < 98 and pxcor > 92 and pxcor < 99 [ face patch 102 92]
        ; if you are along the wall of the brown room
      pycor <= 162 and pycor >= 138 and pxcor >= 31 and pxcor <= 88 [face patch 97 128]
      [face destination]) check-for-walls check-for-crowd]

  ; blue hallway at the north side
  current-patch-color = 87 [ifelse pxcor < 40 [face patch 34 160 check-for-walls check-for-crowd] [face patch 82 159 check-for-crowd]]
  ; brown rooms and toilets at the north side
  current-patch-color = 35.6 or current-patch-color = 63.6 [(ifelse pycor > 170 and pxcor < 63 [ifelse pxcor < 48 [
    face patch 48 175 check-for-walls check-for-crowd] [face patch 60 169 check-for-walls check-for-crowd] ] pycor > 164 and pxcor < 79 [
    face patch 63 167 check-for-walls check-for-crowd] pycor > 162 and pxcor > 79 [
    face patch 79 162 check-for-walls check-for-crowd] [face min-one-of (patches with [pcolor = 84.5 and pxcor > 49 and pxcor < 86]) [distance myself] check-for-walls check-for-crowd]
    )]
  ; yellow room at the north side
  current-patch-color = 44.3 [face patch 141 120 check-for-walls check-for-crowd]

  ; blue room
  current-patch-color = 106.5 [face patch 18 161 check-for-walls check-for-crowd]
  ; purple hallway
  current-patch-color = 125.7 [(ifelse [pycor] of patch-here >= 98 [
          ifelse destination != patch 155 170 [face patch 191 90 check-for-walls check-for-crowd] [
          face patch 155 170 check-for-walls check-for-crowd]] ([pycor] of patch-here < 98)[
    ifelse patch-here = patch 178 75
  ; purple room but not in the hallway first go to a bit before the door and then through the door
    [set key-patch patch 178 75 face patch 168 70 check-for-walls] [ifelse key-patch = patch 178 75 [face patch 168 70] [face patch 178 75]] check-for-crowd]
    )]
  ; yellow room at the south side
  current-patch-color = 44.9 [face patch 203 35 check-for-walls check-for-crowd]
  ; bourdeaux room
  current-patch-color = 12.6 [face patch 148 111 check-for-walls check-for-crowd]
  ; cafeteria
  current-patch-color = 118.1 [face patch 110 149 check-for-walls check-for-crowd]
  ; pink project rooms
  current-patch-color = 137.1 [(ifelse pycor > 123  [
    face patch 30 125 check-for-walls check-for-crowd] pycor > 103 [
    face min-one-of (patch-set patch 31 114 patch 31 105) [distance myself]] pycor > 85 [
    face min-one-of (patch-set patch 32 96 patch 32 87) [distance myself]] pycor > 66 [
    face min-one-of (patch-set patch 33 78 patch 34 69) [distance myself]] pycor > 57 [
    face patch 36 59 check-for-walls check-for-crowd] [face patch 36 50 check-for-walls check-for-crowd])
    check-for-crowd]

  ;; staff spaces

  ; orange rooms
  current-patch-color = 25.6 [(ifelse ycor < 23 [
    (ifelse xcor < 47 [face patch 44 23]
      xcor < 79 [face patch 67 23]
      xcor < 111 [face patch 87 23]
      xcor < 120 [face patch 113 23]
      xcor < 130 [face patch 123 23]
      xcor < 140 [face patch 138 23]
      xcor < 168 [face patch 165 23]
    ycor < 13 and xcor < 182 [face patch 180 13 ]
    ycor < 13 and xcor < 195 [face patch 184 13 ]
    xcor < 179 [face patch 180 20 ]
    xcor < 195 [face patch 180 23 ] )]
    [face patch 195 32 ])
    check-for-walls check-for-crowd]
  ; dark green rooms
  current-patch-color = 72.1 [(ifelse xcor < 75 [face patch 65 30]
    xcor < 84 [ face patch 82 30]
    xcor < 105 [ face patch 96 30]
    xcor < 120 [ face patch 113 30]
    xcor < 127 [ face patch 126 30]
    xcor < 149 [ face patch 137 30]
    xcor < 159 [ face patch 152 30]
    xcor < 177 [ face patch 165 30]
    xcor < 184 [ face patch 179 30]
    [face patch 185 30]) check-for-walls check-for-crowd]
  ; staff toilets
  current-patch-color = 63.6 [ifelse ycor < 35 and xcor < 75 [ face patch 65 30 check-for-walls check-for-crowd]
      [if ycor < 35   [ face patch 82 30 check-for-walls check-for-crowd]]]
  ; code for staff when in the pink hallway
    current-patch-color = 28.7 [face patch 39 27 check-for-walls check-for-crowd]

  ;; special spaces

  ; when you are accidentally in a wall on a staircase or in pink furniture or in the middle of the balie
  current-patch-color = 0 or current-patch-color = 4.5 or current-patch-color = 125.8 [rt 150 fd 2]
  ; in a doorway
  current-patch-color = 84.5 [ifelse one-of neighbors with [pcolor = 9.9] != nobody [face min-one-of (neighbors with [pcolor = 9.9 or pcolor = 118.1]) [abs-hdiff myself self] check-for-walls check-for-crowd] [check-for-walls check-for-crowd]]
  ; at an exit or outside already
  current-patch-color = 14.8 or current-patch-color = 44.6 or current-patch-color = 34.3 [set turtles-safe (turtles-safe + 1) die
      if kid-parent != nobody [ask one-of turtles with [kid-parent = [who] of myself ][die]]]
  ; on stairs and can only walk half as fast, this only happens outside the yellow room at the south side
  current-patch-color = 103.5 [fd 0.5]
  )
  ]]
end

to check-for-walls
  ; is the patch coming up a wall, furniture, stairs or the middle of the front desk? try to avoid it
   if count patches in-cone 2 30 with [pcolor = 0 or pcolor = 125.8 or pcolor = 103.5 or pcolor = 4.5] > 0
    [rt (random 180 - 90)]
      ; if you are almost (within 2 patches) bumping in any of the mentioned above, turn as much as you have to to avoid it
       while [[pcolor] of patch-ahead 2 = 0 or [pcolor] of patch-ahead 2 = 125.8 or [pcolor] of patch-ahead 2 = 103.5 or [pcolor] of patch-ahead 2 = 4.5 or
              [pcolor] of patch-ahead 1 = 0 or [pcolor] of patch-ahead 1 = 125.8 or [pcolor] of patch-ahead 1 = 103.5 or [pcolor] of patch-ahead 1 = 4.5]
        [rt (random 360 - 180)]
end

to check-for-crowd
 if (count [turtles-here] of patch-ahead runningspeed) < 12 [fd runningspeed]
end

to check-for-crowdwalk
 if (count [turtles-here] of patch-ahead walkingspeed) < 12 [fd walkingspeed]
end

to-report abs-hdiff [#t #p] ; find difference in heading, in this version we don't use this
  let _current [heading] of #t
  let _new [towards #p] of #t
  report abs (subtract-headings _current _new)
end

to update-people-closeby [dist]
  ; people in your room with a distance of less than x meter to you
  update-sight 360 dist
  if any? turtles with [(member? [patch-here] of self [patches-in-sight] of myself)] [
    set people-near-me [who] of turtles with [(member? [patch-here] of self [patches-in-sight] of myself)]]
end

to update-sight [angle dist]
  set patches-in-sight patch-set patch-here
  ; scan your angle
  set heading heading - (angle / 2)
  foreach range angle [
    set heading heading + 1
    let wallfound? false
    let more-to-see? false
    ; start with the patches nearest to you
    foreach range dist [ [x] ->
      ; if you are not at the edge of the map
      if not (patch-at-heading-and-distance heading x = nobody) [
        let patchcolor [pcolor] of patch-at-heading-and-distance heading x
        ; if you run into any wall, door or desk, you can't look any further
        if not wallfound? [
        ifelse patchcolor = 0 or patchcolor = 125.8 or patchcolor = 84.5 [set wallfound? true
        set patches-in-sight (patch-set patches-in-sight patch-at-heading-and-distance heading x)] [
        if patchcolor != 0 and patchcolor != 125.8 and patchcolor != 84.5[
              set patches-in-sight (patch-set patches-in-sight patch-at-heading-and-distance heading x) set more-to-see? true]]]
          if not more-to-see? [stop]
  ]]]
  set heading heading - (angle / 2)
end

to show-sight
  ; marks the sight of one of the turtles lightgreen (is a button)
  ask turtle 0 [update-sight 360 30
    ask patches-in-sight [set pcolor green + 2]
  ]
  ask turtle 0 [set color black]

end
@#$#@#$#@
GRAPHICS-WINDOW
224
10
684
497
-1
-1
1.766
1
10
1
1
1
0
0
0
1
0
255
0
270
1
1
1
ticks
30.0

BUTTON
10
10
83
43
NIL
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
11
47
74
80
NIL
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

SWITCH
759
270
880
303
verbose?
verbose?
0
1
-1000

SWITCH
760
306
870
339
debug?
debug?
0
1
-1000

OUTPUT
1053
12
1664
188
12

SLIDER
6
87
178
120
population_visitors
population_visitors
0
500
156.0
1
1
NIL
HORIZONTAL

SLIDER
6
124
178
157
population_staff
population_staff
0
100
45.0
1
1
NIL
HORIZONTAL

PLOT
5
205
205
355
People out of the building
time
people
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"
"pen-1" 1.0 0 -7500403 true "" "plot turtles-safe"

MONITOR
7
364
101
409
Percentage safe
turtles-safe / (population_visitors + population_staff) * 100
1
1
11

MONITOR
5
414
147
459
Time in minutes since alarm
(ticks - alarmtime) / 60
1
1
11

PLOT
759
115
959
265
Max people on patch
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot [count turtles-here] of max-one-of patches [count turtles-here]"

BUTTON
111
49
174
82
Alarm
Alarm
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
118
372
220
405
NIL
show-sight
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
738
25
910
58
Percentage-kids
Percentage-kids
0
20
5.0
1
1
NIL
HORIZONTAL

SLIDER
737
70
912
103
Percentage-old-people
Percentage-old-people
0
20
5.0
1
1
NIL
HORIZONTAL

SWITCH
4
166
183
199
automatic_emergency
automatic_emergency
0
1
-1000

CHOOSER
27
477
200
522
experiment
experiment
"basic" "nearest exit" "exit signs" "flickering exit signs" "everyone to same exit"
4

CHOOSER
26
542
164
587
same_exit
same_exit
"above right exit" "main exit" "below left exit"
2

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
