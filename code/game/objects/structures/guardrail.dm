/obj/structure/guardrail
	name = "guardrail"
	desc = "A guardrail."
	icon = 'icons/obj/structures.dmi'
	icon_state = "guard_rail"
	density = 1
	w_class = ITEMSIZE_NORMAL

	layer = 4
	pressure_resistance = 5*ONE_ATMOSPHERE
	anchored = 1
	flags = ON_BORDER + CONDUCT
	var/maximal_heat = T0C + 100 		// Maximal heat before this window begins taking damage from fire
	var/damage_per_fire_tick = 2.0 		// Amount of damage per fire tick. Regular windows are not fireproof so they might as well break quickly.
	var/health = 10
	var/maxhealth = 10
	var/ini_dir = null
	var/state = 2

/obj/structure/guardrail/examine(mob/user)
	. = ..(user)

	if(health == maxhealth)
		user << "<span class='notice'>It looks fully intact.</span>"
	else
		var/perc = health / maxhealth
		if(perc > 0.75)
			user << "<span class='notice'>It looks a bit wobbly.</span>"
		else if(perc > 0.5)
			user << "<span class='warning'>It looks a bit damaged.</span>"
		else if(perc > 0.25)
			user << "<span class='warning'>It looks moderately flimsy.</span>"
		else
			user << "<span class='danger'>It looks like its about to collapse.</span>"

/obj/structure/guardrail/proc/take_damage(var/damage = 0,  var/sound_effect = 1)
	var/initialhealth = health

	health = max(0, health - damage)

	if(health <= 0)
		fall_apart()
	else
		if(sound_effect)
			playsound(loc, pick(metal_impact_sounds), 100, 1)
		if(health < maxhealth / 4 && initialhealth >= maxhealth / 4)
			visible_message("[src] looks like it's about to collapse!" )
		else if(health < maxhealth / 2 && initialhealth >= maxhealth / 2)
			visible_message("[src] looks seriously damaged!" )
		else if(health < maxhealth * 3/4 && initialhealth >= maxhealth * 3/4)
			visible_message("[src] looks a little flimsy!" )
	return


/obj/structure/guardrail/proc/fall_apart(var/display_message = 1)
	playsound(src, pick(metal_break_sounds), 70)
	if(display_message)
		visible_message("[src] falls to pieces!")
	//if(dir == SOUTHWEST)
	//	var/index = null
	//	index = 0
	//	while(index < 2)
	//		new shardtype(loc) //todo pooling?
	//		if(reinf) PoolOrNew(/obj/item/stack/rods, loc)
	//		index++
	//else
	//	new shardtype(loc) //todo pooling?
	//	if(reinf) PoolOrNew(/obj/item/stack/rods, loc)
	qdel(src)
	return


/obj/structure/guardrail/bullet_act(var/obj/item/projectile/Proj)

	var/proj_damage = Proj.get_structure_damage()
	if(!proj_damage) return

	if(prob(10)) // 10% change that a shot fired through the guard rail will strike the guardrail
		..()
		take_damage(proj_damage)
	else
		. = PROJECTILE_CONTINUE

	return


/obj/structure/guardrail/ex_act(severity)
	switch(severity)
		if(1.0)
			qdel(src)
			return
		if(2.0)
			fall_apart(0)
			return
		if(3.0)
			if(prob(50))
				fall_apart(0)
				return


/// ------------------------------------------------- CAN PASS

/obj/structure/guardrail/CanPass(atom/movable/mover, turf/target)
	usr << "Something is trying to enter"
	if(istype(mover, /obj/item))
		usr << "It was an item trying to enter"
		return 1
	if(istype(mover) && mover.checkpass(PASSGLASS))
		return 1
	if(get_dir(loc, target) & dir)
		return !density

	var/mob/living/M = mover
	if(istype(M))
		if(M.lying)
			return ..()

	return 0

/*
/obj/structure/guardrail/CanPass(atom/movable/A, turf/T)

	if(istype(A) && A.checkpass(A))
		return 1

	if(istype(A, /obj/item))
		usr << "It was an item"
		return 1

	//If you're not lying down or an item, do standard glass check
	//if(get_dir(loc, T) & dir)
	//	return !density

	//If you're lying down you're most likely being thrown, allow thrown people over railings.
	var/mob/living/M = A
	if(istype(M))
		if(M.lying)
			return ..()



	return ..()


	if(istype(A) && A.checkpass(PASSGLASS))
		return prob(80) //Stuff might hit the railing.
	else if(istype(A, /obj/item))
		return 1
	else if(get_dir(loc, T) & dir)
		return !density

	//Don't drive over the edge
	if(istype(A, /obj/vehicle))
		return 0

	//If you're lying down you're most likely being thrown, allow thrown people over railings.
	var/mob/living/M = A
	if(istype(M))
		if(M.lying)
			return ..()
		return issmall(M)

	return ..() */

// -------------------------------------------------- CAN PASS END

// -------------------------------------------------- CAN EXIT
/*
/obj/structure/guardrail/CheckExit(atom/movable/O, target as turf)
	usr << "Something is trying to exit"
	if(istype(O, /obj/item))
		usr << "It was an item trying to exit"
		return 1
	if(istype(O) && O.checkpass(PASSGLASS))
		return 1
	if(get_dir(O.loc, target) == dir)
		return 0
	return 1


/obj/structure/guardrail/CheckExit(atom/O, target as turf)
	if(istype(O, /obj/item))
		usr << "It was an item, I'm letting it through"
		return 1
	else if(istype(O, atom/movable) && O.checkpass(PASSGLASS))
		return 1
	else if(istype(O, /atom/movable))
		if(get_dir(O.loc, target) == dir)
			return 0

	return 1*/

// -------------------------------------------------- CAN EXIT END

/*
/obj/structure/guardrail/hitby(AM as mob|obj)
	..()
	visible_message("<span class='danger'>[src] was hit by [AM].</span>")
	var/tforce = 0
	if(ismob(AM))
		tforce = 40
	else if(isobj(AM))
		var/obj/item/I = AM
		tforce = I.throwforce
	if(health - tforce <= 7)
		anchored = 0
		update_verbs()
		step(src, get_dir(AM, src))
	take_damage(tforce)
*/
/obj/structure/guardrail/attack_tk(mob/user as mob)
	user.visible_message("<span class='notice'>Something knocks on [src].</span>")
	playsound(loc, pick(metal_impact_sounds), 50)

/obj/structure/guardrail/attack_hand(mob/user as mob)
	user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
	if(HULK in user.mutations)
		user.say(pick(";RAAAAAAAARGH!", ";HNNNNNNNNNGGGGGGH!", ";GWAAAAAAAARRRHHH!", "NNNNNNNNGGGGGGGGHH!", ";AAAAAAARRRGH!"))
		user.visible_message("<span class='danger'>[user] smashes through [src]!</span>")
		user.do_attack_animation(src)
		fall_apart()

	else if (usr.a_intent == I_HURT)

		if (istype(usr,/mob/living/carbon/human))
			var/mob/living/carbon/human/H = usr
			if(H.species.can_shred(H))
				attack_generic(H,25)
				return

		playsound(loc, pick(metal_impact_sounds), 80)
		user.do_attack_animation(src)
		usr.visible_message("<span class='danger'>\The [usr] bangs against \the [src]!</span>",
							"<span class='danger'>You bang against \the [src]!</span>",
							"You hear a banging sound.")
	else
		playsound(loc, pick(metal_impact_sounds), 80)
		usr.visible_message("[usr.name] knocks on the [src.name].",
							"You knock on the [src.name].",
							"You hear a knocking sound.")
	return

/obj/structure/guardrail/attack_generic(var/mob/user, var/damage)
	user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
	if(!damage)
		return
	if(damage >= 10)
		visible_message("<span class='danger'>[user] smashes into [src]!</span>")
		take_damage(damage)
	else
		visible_message("<span class='notice'>\The [user] taps \the [src] harmlessly.</span>")
	user.do_attack_animation(src)
	return 1

/obj/structure/guardrail/attackby(obj/item/W as obj, mob/user as mob)
	if(!istype(W)) return//I really wish I did not need this
	if (istype(W, /obj/item/weapon/grab) && get_dist(src,user)<2)
		var/obj/item/weapon/grab/G = W
		if(istype(G.affecting,/mob/living))
			var/mob/living/M = G.affecting
			var/state = G.state
			qdel(W)	//gotta delete it here because if window breaks, it won't get deleted
			switch (state)
				if(1)
					M.visible_message("<span class='warning'>[user] slams [M] against \the [src]!</span>")
					M.apply_damage(7)
					hit(10)
				if(2)
					M.visible_message("<span class='danger'>[user] bashes [M] against \the [src]!</span>")
					if (prob(50))
						M.Weaken(1)
					M.apply_damage(10)
					hit(25)
				if(3)
					M.visible_message("<span class='danger'><big>[user] crushes [M] against \the [src]!</big></span>")
					M.Weaken(5)
					M.apply_damage(20)
					hit(50)
			return

	if(W.flags & NOBLUDGEON) return

	if(istype(W, /obj/item/weapon/wrench))
		update_verbs()
		playsound(loc, 'sound/items/Ratchet.ogg', 75)
		user << (anchored ? "<span class='notice'>You have fastened the window to the floor.</span>" : "<span class='notice'>You have unfastened the window.</span>")
	else if(istype(W, /obj/item/weapon/wirecutters))
		playsound(src.loc, 'sound/items/Wirecutter.ogg', 50)
		user << "<span class='notice'>You start to cut the rail into rods.</span>"
		playsound(src.loc, 'sound/items/Ratchet.ogg', 50)
		if(do_after(user, 10))
			user << "<span class='notice'>You cut the rail into rods.</span>"
			var/obj/item/stack/rods/A = new /obj/item/stack/rods( src.loc )
			A.amount = 4
			qdel(src)
		return
	else
		user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
		if(W.damtype == BRUTE || W.damtype == BURN)
			user.do_attack_animation(src)
			hit(W.force)
			if(health <= 7)
				anchored = 0
				step(src, get_dir(user, src))
		else
			playsound(loc, pick(metal_impact_sounds), 75)
		..()
	return

/obj/structure/guardrail/proc/hit(var/damage, var/sound_effect = 1)
	take_damage(damage)
	return


/obj/structure/guardrail/proc/rotate()
	set name = "Rotate Guard Rail Counter-Clockwise"
	set category = "Object"
	set src in oview(1)

	if(usr.incapacitated())
		return 0

	if(anchored)
		usr << "It is fastened to the floor therefore you can't rotate it!"
		return 0

	set_dir(turn(dir, 90))
	return


/obj/structure/guardrail/proc/revrotate()
	set name = "Rotate Guard Rail Clockwise"
	set category = "Object"
	set src in oview(1)

	if(usr.incapacitated())
		return 0

	if(anchored)
		usr << "It is fastened to the floor therefore you can't rotate it!"
		return 0

	set_dir(turn(dir, 270))
	return

/obj/structure/guardrail/New(Loc, start_dir=null, constructed=0)
	..()

	//player-constructed windows
	if (constructed)
		anchored = 0
		update_verbs()

	if (start_dir)
		set_dir(start_dir)

	health = maxhealth

	ini_dir = dir

	update_nearby_tiles(need_rebuild=1)


/obj/structure/guardrail/Destroy()
	density = 0
	update_nearby_tiles()
	var/turf/location = loc
	loc = null
	for(var/obj/structure/window/W in orange(location, 1))
		W.update_icon()
	loc = location
	..()

/obj/structure/guardrail/Move()
	var/ini_dir = dir
	update_nearby_tiles(need_rebuild=1)
	..()
	set_dir(ini_dir)
	update_nearby_tiles(need_rebuild=1)

//Updates the availabiliy of the rotation verbs
/obj/structure/guardrail/proc/update_verbs()
	if(anchored)
		verbs -= /obj/structure/guardrail/proc/rotate
		verbs -= /obj/structure/guardrail/proc/revrotate
	else
		verbs += /obj/structure/guardrail/proc/rotate
		verbs += /obj/structure/guardrail/proc/revrotate

///obj/structure/guardrail/fire_act(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	//if(!destroyed)
	//	if(exposed_temperature > T0C + 1500)
	//		health -= 1
	//
	//..()

///obj/structure/guardrail/basic
//	desc = "It looks thin and flimsy. A few knocks with... anything, really should shatter it."
//	icon_state = "window"
//	basestate = "window"
//	glasstype = /obj/item/stack/material/glass
//	maximal_heat = T0C + 100


/obj/structure/guardrail/New(Loc, constructed=0)
	..()

	//player-constructed guard rails
	if (constructed)
		state = 0

