//VOX ANNOUNCEMENT SYSTEM
//PORTED FROM /TG/ BY FLATGUB OVER THE COURSE OF TWO PAINFUL DAYS.

var/announcing_vox = 0 // Stores the time of the last announcement
var/const/VOX_CHANNEL = 200
var/const/VOX_DELAY = 10

/////////////////////////////
/// VOX ANNOUNCEMENT HELP ///
/////////////////////////////
// Verb used to show an example of all available words and allows the user to preview words

/mob/living/silicon/ai/verb/announcement_help()

	set name = "Announcement Help"
	set desc = "Display a list of vocal words to announce to the crew."
	set category = "AI Commands"

	if(usr.stat == 2)
		return //won't work if dead

	var/dat = "Here is a list of words you can type into the 'Announcement' button to create sentences to vocally announce to everyone on the same level at you.<BR> \
	<UL><LI>You can also click on the word to preview it.</LI>\
	<LI>You can only say 30 words for every announcement.</LI>\
	<LI>Do not use punctuation as you would normally, if you want a pause you can use the full stop and comma characters by separating them with spaces, like so: 'Alpha . Test , Bravo'.</LI></UL>\
	<font class='bad'>WARNING:</font><BR>Misuse of the announcement system will get you job banned.<HR>"

	var/index = 0
	for(var/word in vox_words)
		index++
		dat += "<A href='?src=\ref[src];say_word=[word]'>[capitalize(word)]</A>"
		if(index != vox_words.len)
			dat += " / "

	var/datum/browser/popup = new(src, "announce_help", "Announcement Help", 500, 400)
	popup.set_content(dat)
	popup.open()

////////////////////
/// ANNOUNCEMENT ///
////////////////////
// Verb used to take input, check for invalid words and schedule announcements. The main method.

/mob/living/silicon/ai/verb/announcement()
	if(announcing_vox > world.time)
		src << "<span class='notice'>Please wait [round((announcing_vox - world.time) / 10)] seconds.</span>"
		return

	var/message = input(src, "WARNING: Misuse of this verb can result in you being job banned. More help is available in 'Announcement Help'", "Announcement", src.last_announcement) as text

	last_announcement = message

	//Time to wait between confirming the announcement and it actually happening
	//more unique words = higher typing time
	//Both adds a form of "typing delay" and gives vox the time required to cache all audio clips before they're needed
	//var/typingtime = 0 -- Unneeded

	if(!message || announcing_vox > world.time)
		return

	if(stat != CONSCIOUS)
		return

	if(control_disabled)
		src << "<span class='notice'>Wireless interface disabled, unable to interact with announcement PA.</span>"
		return


	var/list/words = splittext(trim(message), " ")
	var/list/incorrect_words = list()

	if(words.len > 30)
		words.len = 30

	for(var/word in words)
		word = lowertext(trim(word))
		if(!word)
			words -= word
			continue
		if(!vox_words[word])
			incorrect_words += word

	if(incorrect_words.len)
		src << "<span class='notice'>These words are not available on the announcement system: [english_list(incorrect_words)].</span>"
		return

	announcing_vox = world.time + VOX_DELAY

	log_game("[key_name(src)] made a vocal announcement with the following message: [message].")

	//Force assets to be loaded into cache before playing, incase of unloaded files
	for(var/word in words)
		src << browse_rsc(vox_words[word])

	src << "You enter the announcement"
	typingtime = 10

	spawn(typingtime)
		for(var/word in words)
			play_vox_word(word, src.z, null)

		//Just incase VOX *DOES* fail, all mobs in the current z-level get a text version of the announcement
		for(var/mob/M in player_list)
			if(M.client)
				var/turf/T = get_turf(M)
				var/turf/our_turf = get_turf(src)
				if(T.z == our_turf.z)
					M << "<b><font size = 2><font color = red>AI announcement</b>:</font color> [message]</font size>"



/////////////////////
/// PLAY VOX WORD ///
/////////////////////
// Proc which takes a word and plays the appropriate audio file to the appropriate people. The backbone of this operation.
/proc/play_vox_word(word, z_level, mob/only_listener)

	word = lowertext(word)

	if(vox_words[word])

		var/sound_file = vox_words[word]
		var/sound/voice = sound(sound_file, wait = 1, channel = VOX_CHANNEL)
		voice.status = SOUND_STREAM

 		// If there is no single listener, broadcast to everyone in the same z level
		if(!only_listener)
			// Play voice for all mobs in the z level
			for(var/mob/M in player_list)
				if(M.client && !M.ear_deaf) //People must be clients and people must not be deaf to hear our fabulous annoucements
					var/turf/T = get_turf(M)
					if(T.z == z_level)
						M << voice
		else
			only_listener << voice
		return 1
	return 0

