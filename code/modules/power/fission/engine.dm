#define REACTOR_OUTPUT_MULTIPLIER 3
#define REACTOR_COOLING_FACTOR 0.5
#define REACTOR_TEMPERATURE_CUTOFF 10000

/obj/machinery/power/fission
	icon = 'icons/obj/machines/fission.dmi'
	density = 1
	anchored = 0
	name = "Nuclear Fission Core"
	icon_state = "engine"
	var/gasefficiency = 0.25
	var/envefficiency = 0.01
	var/health = 3000
	var/max_health = 3000
	// Material properties from Tungsten Carbide, otherwise core'll be too weak.
	var/specific_heat = 40	// J/(mol*K)
	var/molar_mass = 0.196	// kg/mol
	var/mass = 2000 // kg
	var/max_temp = 3058
	var/temperature = T20C
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

	equalize(loc.return_air(), envefficiency)

	if(rods.len < 1)	//Nothing to run, yet.
		return

	var/decay_heat = 0
	var/activerods = 0
	for(var/i=1,i<=rods.len,i++)
		var/obj/item/weapon/fuelrod/rod = rods[i]
		if(rod.life > 0)
			decay_heat += rod.tick_life()
			if(rod.reflective)
				activerods++

	add_thermal_energy(decay_heat * activerods)
	equalize_all()

	for(var/i=1,i<=rods.len,i++)
		var/obj/item/weapon/fuelrod/rod = rods[i]
		rod.equalize(src, gasefficiency)

	if(temperature > max_temp) // Overheating, reduce structural integrity, emit more rads.
		health -= health * ((temperature - max_temp) / (max_temp * 2))

	var/healthmul = ((((health / max_health) - 1) / -1) * 10) + 1

	var/power = (decay_heat / 1000) * healthmul
	for(var/mob/living/l in range(src, round(sqrt(power / 2))))
		var/radius = max(get_dist(l, src), 1)
		var/rads = (power / 10) * ( 1 / (radius**2) )
		l.apply_effect(rads, IRRADIATE)

/obj/machinery/power/fission/attackby(var/obj/item/weapon/W as obj, var/mob/user as mob)
	if(!anchored)
		if(istype(W, /obj/item/weapon/wrench))
			playsound(src.loc, 'sound/items/Ratchet.ogg', 50, 1)
			user << "<span class='notice'>You fasten \the [src] into place</span>"
			anchored = 1
			for(var/obj/machinery/atmospherics/pipe/simple/pipe in loc)
				pipes += pipe
			for(var/obj/machinery/atmospherics/pipe/manifold/pipe in loc)
				pipes += pipe
			for(var/obj/machinery/atmospherics/pipe/manifold4w/pipe in loc)
				pipes += pipe
			for(var/obj/machinery/atmospherics/pipe/cap/pipe in loc)
				pipes += pipe
			return
		return ..()

	if(istype(W, /obj/item/weapon/fuelrod))
		user << "<span class='notice'>You carefully start loading \the [W] into to \the [src].</span>"
		if(do_after(user, 40))
			user.drop_from_inventory(W)
			W.loc = src
			rods += W
		return

	if(istype(W, /obj/item/weapon/wirecutters)) // Wirecutters? Sort of like prongs, for removing a rod. Good luck getting a 20kg fuel rod out with wirecutters though.
		if(rods.len == 0)
			user << "<span class='notice'>There's nothing left to remove.</span>"
			return ..()
		for(var/i=1,i<=rods.len,i++)
			var/obj/item/weapon/fuelrod/rod = rods[i]
			if(rod.health == 0 || rod.life == 0)
				user << "<span class='notice'>You carefully start removing \the [rod] from \the [src].</span>"
				if(do_after(user, 40))
					rods -= rod
					rod.loc = src.loc
				return
		var/obj/item/weapon/fuelrod/rod = rods[rods.len]
		user << "<span class='notice'>You carefully start removing \the [rod] from \the [src].</span>"
		if(do_after(user, 40))
			rods -= rod
			rod.loc = src.loc
		return

	if(!istype(W, /obj/item/weapon/wrench))
		return ..()

	add_fingerprint(user)

	if(rods.len > 0)
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

/obj/machinery/power/fission/proc/equalize(datum/gas_mixture/env, var/efficiency)
	var/datum/gas_mixture/sharer = env.remove(efficiency * env.total_moles)
	var/our_heatcap = heat_capacity()
	var/share_heatcap = sharer.heat_capacity()

	if((abs(temperature-sharer.temperature)>MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER) && our_heatcap + share_heatcap)
		var/new_temperature = ((temperature * our_heatcap) + (sharer.temperature * share_heatcap)) / (our_heatcap + share_heatcap)
		temperature += (new_temperature - temperature)
		temperature = between(0, temperature, REACTOR_TEMPERATURE_CUTOFF)
		sharer.temperature += (new_temperature - sharer.temperature)
		sharer.temperature = between(0, sharer.temperature, REACTOR_TEMPERATURE_CUTOFF)

	env.merge(sharer)

/obj/machinery/power/fission/proc/equalize_all()
	var/our_heatcap = heat_capacity()
	var/total_heatcap = our_heatcap
	var/total_energy = temperature * our_heatcap
	for(var/i=1,i<=pipes.len,i++)
		var/obj/machinery/atmospherics/pipe/pipe = pipes[i]
		if (istype(pipe, /obj/machinery/atmospherics/pipe))
			var/datum/gas_mixture/env = pipe.return_air()
			if (!isnull(env))
				var/datum/gas_mixture/removed = env.remove(gasefficiency * env.total_moles)
				var/env_heatcap = env.heat_capacity()
				total_heatcap += env_heatcap
				total_energy += (env.temperature * env_heatcap)
				env.merge(removed)

	if(!total_heatcap)
		return
	var/new_temperature = total_energy / total_heatcap
	temperature += (new_temperature - temperature) * gasefficiency // Add efficiency here, since there's no gas.remove for non-gas objects.
	temperature = between(0, temperature, REACTOR_TEMPERATURE_CUTOFF)

	for(var/i=1,i<=pipes.len,i++)
		var/obj/machinery/atmospherics/pipe/pipe = pipes[i]
		if (istype(pipe, /obj/machinery/atmospherics/pipe))
			var/datum/gas_mixture/env = pipe.return_air()
			if (!isnull(env))
				var/datum/gas_mixture/removed = env.remove(gasefficiency * env.total_moles)
				removed.temperature += (new_temperature - removed.temperature)
				removed.temperature = between(0, removed.temperature, REACTOR_TEMPERATURE_CUTOFF)
				env.merge(removed)

/obj/machinery/power/fission/proc/add_thermal_energy(var/thermal_energy)
	if(mass < 1)
		return 0

	var/heat_capacity = heat_capacity()
	if(thermal_energy < 0)
		if(temperature < TCMB)
			return 0
		var/thermal_energy_limit = -(temperature - TCMB)*heat_capacity	//ensure temperature does not go below TCMB
		thermal_energy = max(thermal_energy, thermal_energy_limit)	//thermal_energy and thermal_energy_limit are negative here.
	temperature += thermal_energy/heat_capacity
	return thermal_energy

/obj/machinery/power/fission/proc/heat_capacity()
	. = specific_heat * (mass / molar_mass)

/obj/machinery/power/fission/proc/get_integrity()
	var/integrity = round(health / max_health * 100)
	integrity = integrity < 0 ? 0 : integrity
	return integrity

/obj/machinery/power/fission/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1)
	if(!src.powered())
		return

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

	data["core_temp"] = temperature

	data["max_temp"] = max_temp

	data["rods"] = new /list(rods.len)
	for(var/i=1,i<=rods.len,i++)
		var/obj/item/weapon/fuelrod/rod = rods[i]
		var/roddata[0]
		roddata["name"] = rod.name
		roddata["integrity_percentage"] = between(0, rod.integrity, 100)
		roddata["life_percentage"] = between(0, rod.life, 100)
		roddata["heat"] = rod.temperature
		roddata["melting_point"] = rod.melting_point
		data["rods"][i] = roddata

	ui = nanomanager.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "fission_engine.tmpl", "Nuclear Fission Core", 500, 300)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)
