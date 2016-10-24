#define REACTOR_COOLING_FACTOR 0.5
#define REACTOR_ENVIRONMENT_COOLING_FACTOR 0.1

/obj/item/weapon/fuelrod
	name = "Fuel Rod"
	desc = "A nuclear rod."
	icon = 'icons/obj/machines/fission.dmi'
	icon_state = "rod"
	var/heat = T20C
	var/integrity = 100
	var/life = 100
	var/lifespan = 3600
	var/specific_heat = 1	// J/(mol*K) - Caluclated by: (specific heat) [kJ/kg*K] * (molar mass) [g/mol] (g/mol = kg/mol * 1000, duh.)
	var/molar_mass = 1	// kg/mol
	var/mass = 1 // kg
	var/melting_point = 3000 // Entering the danger zone.
	var/decay_heat = 0 // GJ/mol (Yes, using GigaJoules per Mole. Storing a whole TeraJoule in Joules would probably give Byond an aneurysm.)

/obj/item/weapon/fuelrod/uranium
	name = "Uranium Fuel Rod"
	desc = "A nuclear fuel rod."
	specific_heat = 28	// J/(mol*K)
	molar_mass = 0.235	// kg/mol
	mass = 20 // kg
	melting_point = 1405
	decay_heat = 19540 // GJ/mol

/obj/item/weapon/fuelrod/beryllium
	name = "Beryllium Reflector"
	desc = "A neutron reflector."
	specific_heat = 16	// J/(mol*K)
	molar_mass = 0.009	// kg/mol
	mass = 20 // kg
	melting_point = 1560

/* No control rods just yet.
/obj/item/weapon/fuelrod/silver
	name = "Silver Control Rod"
	desc = "A nuclear control rod."
	specific_heat = 25	// J/(mol*K)
	molar_mass = 0.108	// kg/mol
	mass = 20 // kg
*/

/obj/item/weapon/fuelrod/proc/heat_capacity()
	. = specific_heat * (mass / molar_mass)

/obj/machinery/power/fission
	icon = 'icons/obj/machines/fission.dmi'
	density = 1
	anchored = 1.0
	name = "Nuclear Fission Core"
	icon_state = "engine"
	var/gasefficency = 0.25
	var/health = 3000
	var/max_health = 3000
	var/list/obj/item/weapon/fuelrod/rods
	var/list/obj/machinery/atmospherics/pipe/pipes

/obj/machinery/power/fission/New()
	. = ..()
	rods = new()
	pipes = new()

/obj/machinery/power/fission/Destroy()
	/*if (!isnull(pipe1))
		qdel(pipe1)
	if (!isnull(pipe2))
		qdel(pipe2)*/
	. = ..()

/obj/machinery/power/fission/process()

	var/turf/L = loc

	if(isnull(L))		// We have a null turf...something is wrong, stop processing this entity.
		return PROCESS_KILL

	if(!istype(L)) 	//We are in a crate or somewhere that isn't turf, if we return to turf resume processing but stop for now.
		return

	if (!anchored || rods.len < 1 || pipes.len < 1)	//Nothing to run, yet.
		return

	var/heat = 0
	var/decay_heat = 0
	var/activerods = 0
	for(var/i=1,i<=rods.len,i++)
		var/obj/item/weapon/fuelrod/rod = rods[i]
		heat += rod.heat
		if (rod.life > 0 && rod.lifespan > 0)
			decay_heat += rod.decay_heat * (min(rod.life, 100) / 100)
			rod.life = max(0, rod.life - (1 / rod.lifespan))
			activerods++
	decay_heat = decay_heat * activerods
	heat = heat / rods.len

	for(var/i=1,i<=pipes.len,i++)
		var/obj/machinery/atmospherics/pipe/pipe = pipes[i]
		if (istype(pipe, /obj/machinery/atmospherics/pipe))
			var/datum/gas_mixture/env = pipe.return_air()
			var/datum/gas_mixture/removed = env.remove(gasefficency * env.total_moles)
			removed.add_thermal_energy(decay_heat / pipes.len)
			removed.temperature = between(0, removed.temperature, 10000)
			heat += (removed.temperature - heat) * REACTOR_COOLING_FACTOR
			env.merge(removed)

	var/datum/gas_mixture/env = loc.return_air()
	var/datum/gas_mixture/removed = env.remove(gasefficency * env.total_moles)
	removed.add_thermal_energy((decay_heat / pipes.len) * REACTOR_ENVIRONMENT_COOLING_FACTOR)
	removed.temperature = between(0, removed.temperature, 10000)
	heat += (removed.temperature - heat) * REACTOR_ENVIRONMENT_COOLING_FACTOR
	env.merge(removed)

	for(var/i=1,i<=rods.len,i++)
		var/obj/item/weapon/fuelrod/rod = rods[i]
		rod.heat = round((rod.heat + heat) / 2)// Equalize fuel heat.
		if (rod.heat > rod.melting_point)
			rod.integrity = 0
		else if (rod.heat > (rod.melting_point * 0.9))
			rod.integrity = max(0, rod.integrity - (1 / rod.lifespan))
		//if (rod.integrity == 0) // Meltdown time.

	var/power = decay_heat / 1000
	for(var/mob/living/l in range(src, round(sqrt(power / 2))))
		var/radius = max(get_dist(l, src), 1)
		var/rads = (power / 10) * ( 1 / (radius**2) )
		l.apply_effect(rads, IRRADIATE)

/obj/machinery/power/fission/attackby(var/obj/item/weapon/W as obj, var/mob/user as mob)
	if (!anchored)
		if (istype(W, /obj/item/weapon/wrench))
			playsound(src.loc, 'sound/items/Ratchet.ogg', 50, 1)
			user << "<span class='notice'>You fasten \the [src] into place</span>"
			anchored = 1
			for (var/obj/machinery/atmospherics/pipe/simple/pipe in loc)
				pipes += pipe
			for (var/obj/machinery/atmospherics/pipe/manifold/pipe in loc)
				pipes += pipe
			for (var/obj/machinery/atmospherics/pipe/manifold4w/pipe in loc)
				pipes += pipe
			for (var/obj/machinery/atmospherics/pipe/cap/pipe in loc)
				pipes += pipe
		return

	if (istype(W, /obj/item/weapon/fuelrod))
		user << "<span class='notice'>You carefully start adding \the [W] to \the [src].</span>"
		if (do_after(user, 40))
			user.drop_from_inventory(W)
			W.loc = src
			rods += W
		return

	if (istype(W, /obj/item/weapon/wirecutters)) // Wirecutters? Sort of like prongs, for removing a rod. Good luck getting a 20kg fuel rod out with wirecutters though.
		for(var/i=1,i<=rods.len,i++)
			var/obj/item/weapon/fuelrod/rod = rods[i]
			if (rod.life == 0)
				user << "<span class='notice'>You carefully start removing \the dead [rod] from \the [src].</span>"
				if (do_after(user, 40))
					rods -= rod
					rod.loc = src.loc
				return
		var/obj/item/weapon/fuelrod/rod = rods[rods.len]
		user << "<span class='notice'>You carefully start removing \the [rod] from \the [src].</span>"
		if (do_after(user, 40))
			rods -= rod
			rod.loc = src.loc
		//ui_interact(user)
		return

	if (!istype(W, /obj/item/weapon/wrench))
		return ..()

	add_fingerprint(user)

	if (rods.len > 0)
		user << "<span class='warning'>You cannot unwrench \the [src], while it contains fuel rods.</span>"
		return 1

	playsound(src.loc, 'sound/items/Ratchet.ogg', 50, 1)
	user << "<span class='notice'>You begin to unfasten \the [src]...</span>"
	if (do_after(user, 40))
		pipes = new()
		anchored = 0

/obj/machinery/power/fission/attack_hand(mob/user as mob)
	ui_interact(user)

/obj/machinery/power/fission/attack_robot(mob/user as mob)
	ui_interact(user)

/obj/machinery/power/fission/attack_ai(mob/user as mob)
	ui_interact(user)

/obj/machinery/power/fission/proc/get_integrity()
	var/integrity = round(health / max_health * 100)
	integrity = integrity < 0 ? 0 : integrity
	return integrity

/obj/machinery/power/fission/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1)
	var/data[0]

	data["integrity_percentage"] = round(get_integrity())
	var/datum/gas_mixture/env = null
	if(!istype(src.loc, /turf/space))
		env = src.loc.return_air()

	if(!env)
		data["ambient_temp"] = 0
		data["ambient_pressure"] = 0
	else
		data["ambient_temp"] = round(env.temperature)
		data["ambient_pressure"] = round(env.return_pressure())

	var/core_temp = 0
	var/max_temp = 3000
	for(var/i=1,i<=rods.len,i++)
		var/obj/item/weapon/fuelrod/rod = rods[rods.len]
		core_temp += rod.heat
		max_temp = min(max_temp, rod.melting_point)
	if (rods.len > 0)
		data["core_temp"] = core_temp / rods.len // Average core heat this tick.
	else
		data["core_temp"] = data["ambient_temp"]
	data["max_temp"] = max_temp

	ui = nanomanager.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "fission_engine.tmpl", "Nuclear Fission Core", 500, 300)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)