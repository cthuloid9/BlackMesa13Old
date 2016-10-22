/obj/structure/safetyrail
	name = "safety rail"
	desc = "To keep you safe, of course."
	icon = 'icons/obj/safetyrail.dmi'
	icon_state = "standard"
	density = 1
	climbable = 1
	layer = 2.8
	throwpass = 1
	anchored = 1

/obj/structure/safetyrail/straight
	icon_state = "standard"

/obj/structure/safetyrail/corner
	icon_state = "corner"

/obj/structure/safetyrail/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(air_group || (height==0)) return 1
	if(istype(mover,/obj/item/projectile))
		return prob(10) //10% chance a bullet'll hit the railing.
	if(istype(mover) && mover.checkpass(PASSTABLE))
		return 1
	if(locate(/obj/structure/safetyrail) in get_turf(mover))
		return 1
	return 0

/obj/structure/safetyrail/CheckExit(atom/movable/O as mob|obj, target as turf)
	return 1