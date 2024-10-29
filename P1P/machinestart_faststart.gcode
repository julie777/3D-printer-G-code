;===== machine: P1P ========================
;===== date: 2023-10-17 =====================
;===== profile: P1P 0.4 nozzle Fast Start
;===== customizer: Julie Jones
;===== description: fast start is intended to be used when printing multiple prints using the same plate
; and filament type. It eliminates all the purging and checking normally done during the machine start,
; making it start similar to the way a Prusa starts.
;
; I typically do one normal start per day and use fast start for the following prints. (I also typically do the bed level calibration during the normal start.)
; All of the code to ensure that the printer is in a known and safe state at the beginning of a print job is retained.
;

; ++++ set bed and nozzle temp ++++
; start the heating process because it will take longer than anything else in the startup process.
; Note, this does not cause a pause waiting for temp to reach set point
; (This could also be a cooling process if a previous print has just completed.)
M140 S[bed_temperature_initial_layer_single]    ; set bed temp

; start heating or cooling the nozzle making sure it is safe to touch the bed
; setting the temp also turns on the fan for the cold end
M104 S140	; this is the temp required for homing (nozzle touching the printable area of the plate
; FIX: this should be conditional
M106 P2 S100 ; turn on aux fan, to help cool down nozzle if it is above 140


;===== reset machine status (std) =================
; this just puts the machine in a known and safe state before beginning configuring for the current print job
G91
M17 Z0.4 ; lower the z-motor current because the next step might bottom out the bed
G0 Z12 F300 ; lower the hotbed , to prevent the nozzle is below the hotbed
G0 Z-6;
G90
M17 X1.2 Y1.2 Z0.75 ; reset motor current to default
G90
M220 S100 ;Reset Feedrate
M221 S100 ;Reset Flowrate
M73.2   R1.0 ;Reset time remaining magnitude
M1002 set_gcode_claim_speed_level : 5
M221 X0 Y0 Z0 ; turn off soft endstop to prevent protential logic problem
G29.1 Z{+0.0} ; clear z-trim value to allow homing properly

; +++++ allow the user to see if a previous print is still on the plate *****
; Raise bed to make it visible in camera
; The goal is to move any previously printed object into view as fast as possible to allow them to be seen before the user switches to another task.
G0 X135 Y253 F20000  ; move to exposed steel surface edge
G28 Z P0 T300; home z with low precision,permit 300deg temperature

; Wait for allowed nozzle temp
; bed needs to be at the correct temp before homing and the nozzle must be 140 or less to prevent damage to plate
M1002 gcode_claim_action : 2  ; set status waiting for bed to heat
M190 S[bed_temperature_initial_layer_single] ;wait for bed temp
M109 S140 ; wait nozzle to be heatbed acceptable whether heating or cooling
G28 ; home	; this touches the nozzle to the bed to home the Z axis

M975 S1 ; turn on vibration compensation
M412 S1 ; turn on filament runout detection

;===== for Textured PEI Plate , lower the nozzle as the nozzle was touching topmost of the texture when homing ==
;curr_bed_type={curr_bed_type}
{if curr_bed_type=="Textured PEI Plate"}
    G29.1 Z{-0.04} ; for Textured PEI Plate
{endif}

;===== print a short line to make sure the nozzle is filled ===============================
; line has been shorted to the minimum necessary
G90 	; absolute posititioning
M83		;
T1000	;
G1 X75.0 Y1.0 Z0.8 F18000   ; Move to start position
M109 S{nozzle_temperature_initial_layer[initial_extruder]}
G1 Z0.2
G0 E2 F300
G0 X200 E15 F{outer_wall_volumetric_speed/(0.3*0.5)     * 60}
;G0 Y11 E0.700 F{outer_wall_volumetric_speed/(0.3*0.5)/ 4 * 60}
;G0 X239.5
;G0 E0.2
;G0 Y1.5 E0.700
;G0 X50 E15 F{outer_wall_volumetric_speed/(0.3*0.5)     * 60}
M400  ; wait for completion


; set ready for print to start
M1002 gcode_claim_action : 0
M106 S0 ; turn off part cooling fan
M106 P2 S0 ; turn off aux fan
M106 P3 S0 ; turn off chamber fan

; this was already turned on above
;M975 S1 ; turn on mech mode supression TODO: how many times do we need to do this?

