/obj/structure/safetyrail
	name = "safety rail"
	desc = "To keep you safe, of course."
	icon = 'icons/obj/safetyrail.dmi'
	icon_state = "standard"
	can_plate = 0
	can_reinforce = 0
	flipped = -1

/obj/structure/safetyrail/straight
	icon_state = "standard"

/obj/structure/safetyrail/corner
	icon_state = "corner"

/obj/structure/safetyrail/New()
	..()
	verbs -= /obj/structure/table/verb/do_flip
	verbs -= /obj/structure/table/proc/do_put

/obj/structure/safetyrail/update_connections()
	return

/obj/structure/safetyrail/update_desc()
	return

/obj/structure/safetyrail/update_icon()
	return
