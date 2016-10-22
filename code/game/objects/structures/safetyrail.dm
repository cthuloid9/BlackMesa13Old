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
	var/manipulating = 0

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

/obj/structure/safetyrail/attackby(obj/item/W as obj, mob/user as mob)
	if (!W) return

	// Handle dismantling or placing things on the table from here on.
	if(isrobot(user))
		return

	if(W.loc != user) // This should stop mounted modules ending up outside the module.
		return

	if(istype(W, /obj/item/weapon/wrench))
		toggle_anchorage(user)
		return

	if(istype(W, /obj/item/weapon/wirecutters))
		if(anchored)
			usr << "<span class='notice'>You cannot cut up \the [src] while it is attached to the floor."
		else
			dismantle(user)
		return


	return

/obj/structure/safetyrail/proc/toggle_anchorage(mob/user)
	if(anchored == 1)
		if(manipulating) return
		manipulating = 1
		user.visible_message("<span class='notice'>\The [user] begins unfastening \the [src] to the floor.</span>",
		                              "<span class='notice'>You begin unfastening \the [src] to the floor.</span>")
		if(!do_after(user, 20))
			manipulating = 0
			return
		manipulating = 0
		user.visible_message("<span class='notice'>\The [user] unfastens \the [src].</span>",
		                              "<span class='notice'>You unfasten \the [src].</span>")
		playsound(src.loc, 'sound/items/Ratchet.ogg', 50)
		anchored = 0
	else
		if(manipulating) return
		manipulating = 1
		user.visible_message("<span class='notice'>\The [user] begins fastening \the [src] to the floor.</span>",
		                              "<span class='notice'>You begin fastening \the [src] to the floor.</span>")
		if(!do_after(user, 20))
			manipulating = 0
			return
		manipulating = 0
		user.visible_message("<span class='notice'>\The [user] fastens \the [src].</span>",
		                              "<span class='notice'>You fasten \the [src].</span>")
		playsound(src.loc, 'sound/items/Ratchet.ogg', 50)
		anchored = 1

	return


/obj/structure/safetyrail/proc/dismantle(mob/user)
	if(anchored) return
	if(manipulating) return
	manipulating = 1
	user.visible_message("<span class='notice'>\The [user] begins cutting up \the [src].</span>",
	                              "<span class='notice'>You begin cutting up \the [src].</span>")
	if(!do_after(user, 20))
		manipulating = 0
		return
	manipulating = 0
	user.visible_message("<span class='notice'>\The [user] cuts up \the [src].</span>",
	                              "<span class='notice'>You cut up \the [src].</span>")
	playsound(src.loc, 'sound/items/Wirecutter.ogg', 50)
	var/obj/item/stack/rods/s =	new /obj/item/stack/rods(src.loc)
	s.amount = 4
	qdel(src)
	return