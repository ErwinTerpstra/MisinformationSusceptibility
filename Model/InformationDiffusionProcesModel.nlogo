extensions [ nw ]

turtles-own [ state susceptibility ] ;; Three states of agents: "B" (believer) ;  "F" (factChecker) ; "S" (susceptible)

links-own [ weigth ]  ;; the weight of the links between agents

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   SETUP   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  ca
  setup-var
  setup-turtles
  update-plot
  reset-ticks
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   GO   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  tick
  if max-ticks > 0 and ticks > max-ticks [stop]   ;; stop condition (300 units of time)

  spreading               ;
  forgetting              ;-- Three main procedures for agent's behavior
  veryfing                ;

  update-colors           ;; just to improve the visualisation
  update-plot             ;; update plots of the Interface
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  SETUP PROCEDURES  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup-var
  set-default-shape turtles "person"
  set-default-shape links "curved link"
  update-output
end

to update-output
  clear-output
  output-print "* Diffusion model in social networks *"
  if Type-of-network = "BA" [output-print "Barabási–Albert network"]
  if Type-of-network = "ER" [output-print "Erdős–Rényi network"]
end

to setup-turtles
  if Type-of-network = "Barabási–Albert algorithm"
  [
    nw:generate-preferential-attachment turtles links number-of-agents min-links-per-agent
    ask turtles [ setxy random-xcor random-ycor ]
  ]
  if Type-of-network = "Erdős–Rényi model"
  [
    clear-output output-print (word "Erdős–Rényi model with " number-of-agents " nodes.")
    nw:generate-random turtles links number-of-agents 0.00585
    ask turtles [ setxy random-xcor random-ycor ]
  ]
  if Type-of-network = "Watts-Strogatz model"
  [
    nw:generate-watts-strogatz turtles links number-of-agents 3 0.1 [ fd 10 ]
  ]
  if Type-of-network = "Small-world model"
  [
    let r ceiling sqrt number-of-agents
    nw:generate-small-world turtles links r r 3.0 false
    ask turtles
    [
      let x who mod r
      let y who / r
      setxy (-15 + (x / r) * 30) (-15 + (y / r) * 30)
    ]
  ]
 init-edges
end

to init-edges
  ask links [set color 3]
  ask turtles
  [
    set susceptibility random-float 1
    let r random-float 1
    ifelse r <= pSetupB
    [ set state "B" ]
    [
      set r r - pSetupB
      ifelse r <= pSetupF
      [ set state "F"]
      [ set state "S"]
    ]
  ]
  update-colors
end

to update-colors
  ask turtles [
    if state = "B" [ set color blue ]
    if state = "F" [ set color red ]
    if state = "S" [ set color gray ]
  ]
end

to update-plot
  set-current-plot "State-of-people"
  set-current-plot-pen "BELIEVERS"
  plot count turtles with [state = "B"]
  set-current-plot-pen "FACT-CHECKERS"
  plot count turtles with [state = "F"]
  set-current-plot-pen "SUSCEPTIBLES"
  plot count turtles with [state = "S"]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  GO PROCEDURES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to spreading  ;; each agent modifies with some probability its state considering the points of view (states) of its neighbors;
  ; S -> B and S -> F according to:
  ; S -> B : "spreading" function for the hoax (fi)
  ; S -> F : disseminate among the immediate neighborhood of a vertex (gi)
  ask turtles with [state = "S" ] [
    let nB count link-neighbors with [state = "B"] ; n-of neighbors Believers
    let nF count link-neighbors with [state = "F"] ; n-of neighbors Fact-checkers

    let credibility alpha-hoaxCredibility
      ; NOTE (Erwin): Added susceptibility factor for hoax credibility
;    if enable-susceptibility [
;      set credibility credibility * susceptibility
;    ]

    let _1PlusA ( 1 + credibility)
    let _1MinusA ( 1 - credibility)
    let den (nB * _1PlusA + nF * _1MinusA)
    let f 0
    let g 0
    if den != 0 [
      set f beta-spreadingRate * ( nB * _1PlusA / den )
      set g beta-spreadingRate * ( nF * _1MinusA / den )
    ]

      ; NOTE (Erwin): Added susceptibility factor for spreading probabilitie
    if enable-susceptibility [
     set f f * susceptibility
     set g g * (1.0 - susceptibility)
    ]

    let random-val-f random-float 1
    ifelse random-val-f < f
    [ set state "B" ]
    [ if random-val-f < (f + g) [ set state "F" ]
    ]
  ]
end

to forgetting  ;; B -> S; F -> S  -- Each agent, regardless of belief state, forgets the news with a fixed probability pforget
  ask turtles with [state = "B" or state = "F"][
    let r random-float 1
    let p pForget

    ; NOTE (Erwin): Added susceptibility factor forgetting
    if enable-susceptibility and enable-anchoring [
     set p p * (1.0 - susceptibility)
    ]

    if r < p [
      set state "S"
    ]
  ]
end

to veryfing  ;; B-> F ; each agent can fact-check the hoax with a fixed probability pverify;
  ask turtles with [state = "B"][
    let r random-float 1
    let p pverify

    ; NOTE (Erwin): Added susceptibility factor for fact checking, and a threshold so that not every agent will ever fact check
    if enable-susceptibility [
      ifelse susceptibility > max-susceptibility-to-verify
      [ set p 0.0 ]
      [ set p p * (1.0 - susceptibility) ]
    ]


    if r < p [
      set state "F"
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
290
10
727
448
-1
-1
13.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
5
388
78
450
SETUP
setup\n
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
163
390
218
423
go-once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
2
247
136
280
pForget
pForget
0
0.2
0.1
0.005
1
NIL
HORIZONTAL

SLIDER
2
281
136
314
pVerify
pVerify
0
0.2
0.05
0.005
1
NIL
HORIZONTAL

SLIDER
136
244
286
277
beta-spreadingRate
beta-spreadingRate
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
137
279
287
312
alpha-hoaxCredibility
alpha-hoaxCredibility
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
3
37
141
70
number-of-agents
number-of-agents
0
1000
1000.0
10
1
NIL
HORIZONTAL

PLOT
730
72
1158
320
State-of-people
NIL
NIL
0.0
100.0
0.0
1000.0
true
true
"set-plot-y-range 0 number-of-agents" ""
PENS
"BELIEVERS" 1.0 0 -13345367 true "" ""
"SUSCEPTIBLES" 1.0 0 -7500403 true "" ""
"FACT-CHECKERS" 1.0 0 -2674135 true "" ""

MONITOR
1066
166
1141
211
Believers
count turtles with [state = \"B\"]
0
1
11

MONITOR
1066
213
1141
258
Susceptibles
count turtles with [state = \"S\"]
0
1
11

MONITOR
1066
260
1141
305
Fact-checker
count turtles with [state = \"F\"]
0
1
11

MONITOR
835
340
905
385
# Vertices
count turtles
17
1
11

BUTTON
81
388
154
450
GO
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
906
340
977
385
# Edges
count links
1
1
11

BUTTON
835
405
915
438
Spring layout
repeat 50 [ layout-spring turtles links 0.2 5 1 ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
77
169
281
214
Type-of-network
Type-of-network
"Barabási–Albert algorithm" "Erdős–Rényi model" "Watts-Strogatz model" "Small-world model"
0

TEXTBOX
5
13
88
33
Initial setting
14
0.0
1

TEXTBOX
3
228
103
246
Hoaxes diffusion
14
0.0
1

TEXTBOX
6
171
56
189
Graph
14
0.0
1

TEXTBOX
740
413
831
431
Improve layout:
12
0.0
1

TEXTBOX
739
352
837
370
Graph metrics:
13
0.0
1

BUTTON
917
405
986
438
Expansion
ask turtles [fd 1]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
978
340
1058
385
Avg. Degree
sum([count link-neighbors] of turtles) / count turtles
3
1
11

OUTPUT
730
10
1158
70
11

TEXTBOX
1069
149
1123
169
#Agents:
13
0.0
1

TEXTBOX
7
368
157
387
Main commands
14
0.0
1

SLIDER
151
37
288
70
min-links-per-agent
min-links-per-agent
1
5
3.0
1
1
NIL
HORIZONTAL

SLIDER
99
79
191
112
pSetupB
pSetupB
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
194
79
286
112
pSetupF
pSetupF
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
4
78
96
111
max-ticks
max-ticks
0
10000
300.0
5
1
NIL
HORIZONTAL

SLIDER
2
317
283
350
max-susceptibility-to-verify
max-susceptibility-to-verify
0
1
0.25
0.01
1
NIL
HORIZONTAL

SWITCH
1
125
147
158
enable-susceptibility
enable-susceptibility
0
1
-1000

SWITCH
150
124
283
157
enable-anchoring
enable-anchoring
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

An agent-based framework to simulate the diffusion process of a piece of misinformation according to a known compartmental model in which the fake news and its debunking compete in a social network.


## HOW IT WORKS

Each agent may be a Believer, a Susceptible, or a Fact-checker (acording to a "State" variable).
Every unit of time agents modify (with a certain probability) their State by considering the neighbors' "states".


## HOW TO USE IT

Set up the model by modifying the number of agents, the Hoaxes Diffusion parameters and the type of network (Barabasi-Albert or Erdos-Reni).

The graph on the right visualizes the amount of agents for each different type of State.


## THINGS TO TRY

Change the network type to investigate the impact on diffusion processes.
Improve the layout of BA network with a Spring layout.


## EXTENDING THE MODEL

#1 Perform parameter sweeping analysis (e.g., behaviourspace) to compute a certain ampount of test to find average and deviation standard values.
 
#2 Include different network configuration to investigate changes in the model

#3 Start the diffusion process from a certain node (e.g., from a node with high centrality or hub)


## CREDITS AND REFERENCES

Sulis, E., Tambuscio, M. (2020). Simulation of misinformation spreading processes in social networks: an application with NetLogo. In 2020 IEEE International Conference on Data Science and Advanced Analytics (DSAA), IEEE.
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
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="EX1. Baseline" repetitions="300" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 301</exitCondition>
    <metric>count turtles with [state = "B"]</metric>
    <metric>count turtles with [state = "F"]</metric>
    <metric>count turtles with [state = "S"]</metric>
    <enumeratedValueSet variable="Type-of-network">
      <value value="&quot;Barabási–Albert algorithm&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pSetupB">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pSetupF">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pVerify">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pForget">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha-hoaxCredibility">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-spreadingRate">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-agents">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-links-per-agent">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-susceptibility-to-verify">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="enable-susceptibility">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="enable-anchoring">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="EX2. WithoutAnchoring" repetitions="300" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 301</exitCondition>
    <metric>count turtles with [state = "B"]</metric>
    <metric>count turtles with [state = "F"]</metric>
    <metric>count turtles with [state = "S"]</metric>
    <enumeratedValueSet variable="Type-of-network">
      <value value="&quot;Barabási–Albert algorithm&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pSetupB">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pSetupF">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pVerify">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pForget">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha-hoaxCredibility">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-spreadingRate">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-agents">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-links-per-agent">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-susceptibility-to-verify">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
      <value value="0.6"/>
      <value value="0.7"/>
      <value value="0.8"/>
      <value value="0.9"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="enable-susceptibility">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="enable-anchoring">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="EX3. WithAnchoring" repetitions="300" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 301</exitCondition>
    <metric>count turtles with [state = "B"]</metric>
    <metric>count turtles with [state = "F"]</metric>
    <metric>count turtles with [state = "S"]</metric>
    <enumeratedValueSet variable="Type-of-network">
      <value value="&quot;Barabási–Albert algorithm&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pSetupB">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pSetupF">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pVerify">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pForget">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha-hoaxCredibility">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-spreadingRate">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-agents">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-links-per-agent">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-susceptibility-to-verify">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
      <value value="0.6"/>
      <value value="0.7"/>
      <value value="0.8"/>
      <value value="0.9"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="enable-susceptibility">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="enable-anchoring">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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

curved link
1.5
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
