/obj/structure/table/safetyrail
	name = "safety rail"
	desc = "To keep you safe, of course."
	icon = 'icons/obj/structures.dmi'
	icon_state = "safety_rail"
	can_plate = 0
	can_reinforce = 0
	flipped = -1

/obj/structure/table/safetyrail/New()
	..()
	verbs -= /obj/structure/table/verb/do_flip
	verbs -= /obj/structure/table/proc/do_put

/obj/structure/table/safetyrail/update_connections()
	return

/obj/structure/table/safetyrail/update_desc()
	return

/obj/structure/table/safetyrail/update_icon()
	return
