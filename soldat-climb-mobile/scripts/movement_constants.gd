## Movement Constants - Direct port from Soldat's Constants.pas and Sprites.pas

class_name MovementConstants
extends RefCounted

const RUNSPEED: float = 0.118
const RUNSPEEDUP: float = RUNSPEED / 6.0
const FLYSPEED: float = 0.03
const JUMPSPEED: float = 0.66
const CROUCHRUNSPEED: float = RUNSPEED / 0.6
const PRONESPEED: float = RUNSPEED * 4.0
const ROLLSPEED: float = RUNSPEED / 1.2
const JUMPDIRSPEED: float = 0.30

const GRAV: float = 0.06
const PLAYER_GRAVITY: float = 1.06 * GRAV

const SURFACECOEFX: float = 0.970
const SURFACECOEFY: float = 0.970
const CROUCHMOVESURFACECOEFX: float = 0.850
const CROUCHMOVESURFACECOEFY: float = 0.970
const STANDSURFACECOEFX: float = 0.000
const STANDSURFACECOEFY: float = 0.000

const SLIDELIMIT: float = 0.2
const MAX_VELOCITY: float = 11.0
const PHYSICS_TIMESTEP: float = 1.0
const V_DAMPING: float = 0.99

const JUMP_FORCE_START_FRAME: int = 9
const JUMP_FORCE_END_FRAME: int = 14
const SIDEJUMP_FORCE_START_FRAME: int = 4
const SIDEJUMP_FORCE_END_FRAME: int = 10
const BACKFLIP_BOOST_START_FRAME: int = 2
const BACKFLIP_BOOST_END_FRAME: int = 7

const BACKFLIP_JUMP_BOOST: float = 0.45  # JUMPDIRSPEED * 1.5
const BACKFLIP_X_DAMPEN: float = 0.5
const BACKFLIP_VEL_X_DAMPEN: float = 0.8

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
