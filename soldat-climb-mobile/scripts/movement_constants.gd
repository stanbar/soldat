## Movement Constants - Direct port from Soldat's Constants.pas and Sprites.pas
## These values define the exact "feel" of Soldat movement.
## DO NOT CHANGE unless intentionally altering the game feel.

class_name MovementConstants

# From Constants.pas lines 39-49
const RUNSPEED: float = 0.118
const RUNSPEEDUP: float = RUNSPEED / 6.0  # slight upward force while running
const FLYSPEED: float = 0.03  # air control (much weaker than ground)
const JUMPSPEED: float = 0.66  # vertical jump impulse
const CROUCHRUNSPEED: float = RUNSPEED / 0.6
const PRONESPEED: float = RUNSPEED * 4.0
const ROLLSPEED: float = RUNSPEED / 1.2
const JUMPDIRSPEED: float = 0.30  # side jump impulse

# From Cvar.pas lines 225-234
const GRAV: float = 0.06
const PLAYER_GRAVITY: float = 1.06 * GRAV  # gostek skeleton gravity
const BULLET_GRAVITY: float = GRAV * 2.25
const SPARK_GRAVITY: float = GRAV / 1.4

# From Sprites.pas lines 24-31 - surface friction coefficients
const SURFACECOEFX: float = 0.970
const SURFACECOEFY: float = 0.970
const CROUCHMOVESURFACECOEFX: float = 0.850
const CROUCHMOVESURFACECOEFY: float = 0.970
const STANDSURFACECOEFX: float = 0.000  # instant stop when standing
const STANDSURFACECOEFY: float = 0.000
const GRENADE_SURFACECOEF: float = 0.880
const SPARK_SURFACECOEF: float = 0.700

# From Sprites.pas lines 50-51
const SLIDELIMIT: float = 0.2
const MAX_VELOCITY: float = 11.0

# Physics timestep
const PHYSICS_TIMESTEP: float = 1.0  # Verlet timestep
const TICKS_PER_SECOND: int = 60

# Verlet damping (from Parts.pas)
const V_DAMPING: float = 0.99

# Animation frame windows for physics impulses
# These are CRITICAL - they define when forces are applied during animations
const JUMP_FORCE_START_FRAME: int = 9
const JUMP_FORCE_END_FRAME: int = 14  # exclusive (< 15 in original)
const SIDEJUMP_FORCE_START_FRAME: int = 4
const SIDEJUMP_FORCE_END_FRAME: int = 10  # exclusive (< 11 in original)
const BACKFLIP_BOOST_START_FRAME: int = 2
const BACKFLIP_BOOST_END_FRAME: int = 7  # exclusive (< 8 in original)

# Backflip jump boost multiplier (from Control.pas line 1614)
const BACKFLIP_JUMP_BOOST: float = JUMPDIRSPEED * 1.5
const BACKFLIP_X_DAMPEN: float = 0.5
const BACKFLIP_VEL_X_DAMPEN: float = 0.8

# Polygon types (from PolyMap.pas lines 22-47)
const POLY_TYPE_NORMAL: int = 0
const POLY_TYPE_ONLY_BULLETS: int = 1
const POLY_TYPE_ONLY_PLAYER: int = 2
const POLY_TYPE_DOESNT_COLLIDE: int = 3
const POLY_TYPE_ICE: int = 4
const POLY_TYPE_DEADLY: int = 5
const POLY_TYPE_BLOODY_DEADLY: int = 6
const POLY_TYPE_HURTS: int = 7
const POLY_TYPE_REGENERATES: int = 8
const POLY_TYPE_LAVA: int = 9
const POLY_TYPE_BOUNCY: int = 18
