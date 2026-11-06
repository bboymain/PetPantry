-- English defaults load first on every client. See TRANSLATING.md.
local _, ns = ...
ns.L = {}
local L = ns.L

-- Interface text. Keep formatting placeholders and WoW color codes intact.
L.LEFT_CLICK = "Left-click"
L.RIGHT_CLICK = "Right-click"
L.SHIFT_LEFT_CLICK = "Shift + Left-click"
L.CTRL_LEFT_CLICK = "Ctrl + Left-click"
L.ALT_LEFT_CLICK = "Alt + Left-click"
L.THEME_FOREVER = "Forever"
L.THEME_OBSIDIAN = "Obsidian"
L.THEME_TEAL = "Teal"
L.THEME_CRIMSON = "Crimson"
L.GENERIC_NOISE = "*makes happy pet noises*"
L.ADDON_NAME = "Pet Pantry"
L.FEED_PET = "Feed pet"
L.HAPPY_SKIP = "Pet is Happy - not feeding"
L.NO_FOOD = "No listed pet food in your bags (/pfeed)"
L.PET_XP = "Pet XP: %d / %d (%d%%)"
L.SPEECH_BUBBLE = "Speech bubble"
L.DRAG_BUBBLE = "Drag me anywhere, then click Done"
L.FOOD = "food"
L.MILESTONE = "MILESTONE"
L.NEXT = "NEXT"
L.XP_UNAVAILABLE = "|cff808080XP not available|r"
L.MAX = "MAX"
L.DEAD = "|cff999999Dead|r"
L.NO_PET = "No pet out"
L.CALL_PET = "Call your pet to feed it"
L.FOOD_PRIORITY = "FOOD PRIORITY"
L.FOOD_PRIORITY_HELP = "Top is eaten first. Only listed food is used."
L.CALL_PET_FIRST = "|cffffd24dPet Pantry:|r call your pet first."
L.ADD_FOOD = "+ Add food from bags"
L.DRAG_FOOD = "...or drag food from your bags into this window"
L.SETTINGS = "SETTINGS"
L.THEME = "Theme"
L.PORTRAIT_CLICK = "Portrait click"
L.GLOW_HUNGRY = "Glow portrait when hungry"
L.SKIP_HAPPY = "Don't feed when pet is Happy"
L.ANNOUNCE_MEALS = "Pet announces its meals"
L.VENDOR_ALERT = "Tell me when vendors sell pet food"
L.COMBAT_CHATTER = "Pet talks in combat (low health, death)"
L.SOUNDS = "Sounds (munch, whimper, fanfare)"
L.IDLE_CHATTER = "Idle chatter"
L.SHARE_CHAT = "Share lines in chat"
L.RESET = "Reset"
L.WARN_FOOD = "Warn when food below (0 = off)"
L.CREDIT = "Made with |cffff6680<3|r by Matt"
L.OFF = "Off"
L.DONE = "Done"
L.MOVE = "Move"
L.BY_MATT = "by Matt"
L.MINIMAP_HELP = "Click to open. Drag to move."
L.DEBUG_SAVED = "|cffffd24dPet Pantry:|r debug snapshot saved. Type /reload so it gets written to disk."
L.CLICK_TO_FEED = "%s to feed:"
L.ITEM = "item %d"
L.LOW_FOOD = "|cffffd24dPet Pantry:|r only %d pet food left!"
L.MEALS_REACHED = "%s reached %d meals!"
L.TITLE_UNLOCKED = "Title unlocked: %s the %s"
L.MILESTONE_EMOTE = "celebrates! %s reached %d meals and is now %s the %s!"
L.MILESTONE_CHAT = "%s reached %d meals and is now %s the %s!"
L.VENDOR_FOOD = "|cffffd24dPet Pantry:|r %s eats: %s"
L.LEVEL = "Lvl %d"
L.XP_GAIN = "+%d XP"
L.PET_TITLE = "%s the %s"
L.PET_INFO = "%s  Lvl %d %s  |cff808080%s|r"
L.MEAL_COUNT_ONE = "%d meal"
L.MEAL_COUNT_MANY = "%d meals"
L.ADDED_FOOD_ONE = "|cffffd24dPet Pantry:|r added %d food."
L.ADDED_FOOD_MANY = "|cffffd24dPet Pantry:|r added %d foods."
L.IDLE_INTERVAL = "Every ~%d min"
L.ITEM_COUNT = "x%d"
L.PET_CHAT = "%s: %s"
L.XP_PROGRESS = "%s / %s  |cffffffff%d%%|r"

-- Game-localized family name -> stable English family key.
L.FAMILY_KEYS = {}

-- Pet dialogue, noises, moods, and milestone titles.
L.MOODS = {"|cffff4033Unhappy|r", "|cffffd24dContent|r", "|cff4dff4dHappy|r"}

L.NOISES = {
    Wolf = "*howls*", Cat = "*purrs*", Bear = "*growls*", Boar = "*snorts*", Spider = "*clicks mandibles*",
    Raptor = "*screeches*", Bat = "*squeaks*", Owl = "*hoots*", Crab = "*clacks claws*", Gorilla = "*beats chest*",
    Turtle = "*slowly blinks*", Crocolisk = "*snaps jaws*", Hyena = "*cackles*", Scorpid = "*clicks pincers*",
    ["Carrion Bird"] = "*caws*", ["Wind Serpent"] = "*hisses*", Tallstrider = "*squawks*",
}

L.CHATTER = { -- what your pet "says" in the card, by mood
    [1] = {
        "I could eat a murloc. Raw.",
        "Feed me or I walk.",
        "*stomach growls loudly*",
        "Is that jerky? Please.",
        "I've started eyeing your boots.",
        "Hunger level: Onyxia.",
        "I'd eat a Defias Pillager right now. Armor and all.",
        "You eat. I watch. This is abuse.",
        "*chews on your quiver*",
        "One more fight on an empty stomach and I'm joining the Horde. Or the Alliance. Whoever feeds me.",
        "My loyalty is dropping. Just saying.",
        "I dreamt of Roasted Quail again.",
    },
    [2] = {
        "A snack wouldn't hurt.",
        "I'm fine. Mostly.",
        "Could go for a bite.",
        "*sniffs your bags*",
        "I'm not hungry. I'm just... looking.",
        "Is that a Tough Jerky in your bag or are you happy to see me?",
        "Snack o'clock is approaching.",
        "I'd hunt better with a treat. Science.",
        "*stares at you. Stares at bag. Stares at you.*",
        "Content. Not thrilled. Content.",
    },
    [3] = {
        "Best hunter ever.",
        "Ready to hunt!",
        "*happy tail wag*",
        "Full belly, sharp claws.",
        "Point me at something. Anything.",
        "I'd die for you. Actually, I have. Several times.",
        "Who needs mounts when you have me?",
        "{noise} happily",
        "{noise} Let's GO!",
        "Pull the whole camp. I believe in us.",
        "Life is good. Loot is better.",
        "I'll tank this. Probably.",
        "10/10 would be tamed again.",
    },
    dead = {
        "...",
        "*needs a Revive Pet*",
        "Tell my story at the stables.",
        "I regret nothing. Except that pull.",
        "Was that the tank's job? It was, wasn't it.",
    },
    none = {
        "Your pet misses you.",
        "It's quiet without a pet.",
        "Somewhere, a stable master is feeding your pet worse food.",
        "Hunters without pets are just... rogues with bows.",
    },
}

L.MILESTONES = { -- meals -> title the pet earns
    {10, "Snacker"}, {50, "Foodie"}, {100, "Gourmet"}, {250, "Glutton"},
    {500, "Bottomless Pit"}, {1000, "Legend of the Feast"},
}

L.STUFFED = { -- "Don't feed when Happy" is on, so nothing gets eaten
    "I'm stuffed. Seriously.",
    "One more bite and I explode.",
    "*turns away from the food dramatically*",
    "Hunter, I am FULL. Respect the belly.",
    "Do I look hungry? Don't answer that.",
    "*lies down and plays dead*",
    "Wafer-thin mint? No. NO.",
    "I'm not a garbage disposal, I'm a companion.",
    "Save it for later. Or for the warlock's imp.",
    "My belly has reached max level.",
    "If I eat that I'll need a bigger hitbox.",
    "Food? Again? I'm too full to even growl.",
    "*unbuckles belt it doesn't have*",
    "Stop. I already can't fit through doors.",
    "Are you gonna eat me later? I'm already full.",
    "I can't help you, I'm in a food coma.",
    "*barfs a little bit* Uh... no.",
    "Are you fattening me up for something? Be honest.",
    "I've eaten so much I can see my own aggro radius.",
    "Not now, I'm digesting. It's a full-time job.",
    "*burps loudly* ...excuse me. No.",
    "Put it in the bank. I'll eat it next expansion.",
    "My stomach just filed a complaint.",
    "If you feed me again, I'm legally a mount.",
    "I physically cannot. My legs don't reach the ground anymore.",
    "Is this a feeding or an intervention?",
    "*waddles away slowly*",
    "No. Nope. Stomach's closed. Come back tomorrow.",
    "I'm so full I'm seeing Roasted Quail when I close my eyes.",
    "Hunter, I love you, but I will throw up on your boots.",
}

L.FORCED = { -- the setting is off, so the food goes down anyway
    "*chews reluctantly*",
    "Fine. FINE. But I'm not happy about it. Well, I am. That's the problem.",
    "*food coma intensifies*",
    "You're going to need a bigger stable.",
    "This is how pets become mounts.",
    "*eats it anyway, glares at you*",
    "Don't expect me to run after this.",
    "I will remember this at the next wipe.",
    "Next time, feed the tank.",
}

L.SHARE = {"Off", "Emote (nearby)", "Party / Raid"}

L.EMOTE_FRAMES = { -- "Nami <frame>" in chat
    "translates for %s: %s",
    "nods as %s says: %s",
    "hears %s mutter: %s",
    "glances at %s, who says: %s",
    "pats %s, who replies: %s",
    "sighs as %s announces: %s",
    "listens to %s's commentary: %s",
    "rolls their eyes. %s says: %s",
}

L.YUM = {
    "%s! *nom nom*",
    "Mmm, %s!",
    "*devours the %s*",
    "%s? My favorite!",
    "*crunch* ...%s. Delicious.",
    "%s! You DO love me.",
    "5 stars. Would eat %s again.",
    "*inhales the %s whole*",
    "Ahh, %s. Just like mom used to hunt.",
    "%s! Worth every copper you didn't pay.",
}

L.VENDOR = {
    "Ooh! They sell snacks here!",
    "Buy the food. Buy ALL the food.",
    "I smell snacks. Don't pretend you don't.",
    "Hunter. HUNTER. Look at the menu.",
    "This vendor gets my vote.",
}

L.LOW = {
    "I'm seeing a white light. Is that Mend Pet?",
    "Hunter, this is where you press Mend Pet.",
    "Tis but a scratch! ...several scratches.",
    "Why am I tanking?! I'm a pet!",
    "Feign Death?! Can I do that too?!",
    "If I die, I'm haunting your bank.",
    "My health bar is looking VERY red.",
    "I didn't sign up for this. I was TAMED.",
    "Remember me as I was: fluffy.",
    "Not the face! Not the face!",
    "Tell the Stable Master... I loved him.",
    "Heal me or I'm eating your hearthstone.",
    "Is it too late to be a warlock's pet?",
    "Pulling aggro was YOUR job!",
    "I can see my whole tamed life flashing before my eyes.",
    "Remember when you fed me that Tough Jerky? Good times.",
    "This is fine. Everything is fine. *is on fire*",
    "Quick, Feign Death! No wait, that only saves YOU.",
    "Mend Pet. Mend Pet! MEND. PET.",
    "Can we talk about my hazard pay?",
    "Is this the part where you Feign Death and leave me? AGAIN?",
    "I'd like to speak to the Stable Master.",
    "Should I be seeing double? I'm seeing double.",
    "Bite harder, they said. It'll be fun, they said.",
    "I'm too loyal for this.",
    "Plot twist: I'M the one who needs Revive Pet.",
    "Somebody call a Druid!",
    "Low health, high spirits! Mostly low health.",
    "Hey! Hey! Your pet is dying over here!",
    "I'll just... lie down for a sec.",
    "Wait, whose side is the healer on?",
    "Oh no. Oh no no no no.",
    "*whimpers in a way that's somehow still adorable*",
    "My last snack better not have been jerky.",
}

L.DEATH = {
    "Worth it.",
    "Avenge meeeee...",
    "Tell my cubs I love them.",
    "Revive Pet... costs mana, right? Right?",
    "I blame the tank.",
    "Well. That was a pull.",
    "*dramatic death noises*",
    "At least I died Happy. Well fed, even.",
    "I'll be in the spirit stable if you need me.",
    "Should've tamed a turtle.",
    "Tell the stable I died doing what I loved. Tanking. Badly.",
    "*spirit floats away, stealing one last treat*",
    "Revive me, and this time bring snacks.",
    "Death: 1. Pet: 0.",
    "I left my dinner in your bag. Don't eat it.",
    "Gah! Not like this! Not before second breakfast!",
    "My only regret... is not biting harder.",
    "I see a light... and it smells like Roasted Quail.",
    "Resurrect me in 3... 2... hello?",
    "Plz no dismiss. Revive.",
    "Guess I'm a ghost pet now. Boo.",
    "*falls over dramatically, one paw twitching*",
}

L.RELIEF = {
    "Phew. Thanks for the heal.",
    "I'm back, baby!",
    "Mend Pet is my love language.",
    "That was totally on purpose.",
    "Nobody saw that. Nobody.",
    "I wasn't scared. You were scared.",
    "Did someone call a vet? Oh wait, that was you.",
    "Healed and hungry. Snack break?",
    "Okay, NOW I'm angry.",
    "Round two. Let's go.",
    "I meant to do that. It was a strategy.",
    "Remind me to bite that guy's ankles later.",
    "Health restored! Dignity... still pending.",
    "You DO care!",
}

L.IDLE = {
    "Are we there yet?",
    "I smell a rare spawn. Probably.",
    "*chases own tail*",
    "Can we go fishing? You fish, I eat.",
    "That murloc looked at me funny.",
    "Is it snack time? It feels like snack time.",
    "*sniffs the air suspiciously*",
    "I'm bored. Pull something.",
    "You've been staring at your bags for a while.",
    "Remember when I was level 1? Good times.",
    "*yawns*",
    "I could take that guy. Just saying.",
    "Let's go bother some gnolls.",
    "Do you ever think about the Stable Master? Me neither.",
    "*digs a hole for no reason*",
    "If you go AFK, I'm eating the jerky.",
    "I think I saw a gold coin over there.",
    "Best pet on this server. Confirm?",
    "*rolls over for belly rubs*",
    "Ready when you are. Dungeon? Also ready. Probably.",
    "Did you hear that? ...Me neither. Let's hunt anyway.",
    "I'm not saying I'm hungry, but I'm hungry.",
    "{noise}",
    "{noise} ...sorry, wrong emote.",
    "Is that a quest giver? Don't talk to them. They'll make us kill 10 boars.",
    "Your mount gets more attention than me.",
    "Pretty sure that bush moved.",
    "I don't want to alarm you, but I think we're lost.",
    "*sniffs a flower, sneezes*",
    "One day I'll get my own action bar.",
    "Do the guards know I'm a good pet? Tell the guards.",
    "Rate my stance: 10/10 alert.",
}

L.FAMILY_IDLE = {
    Wolf = {"Can I pee on that Defias? Just once?", "The moon is out. I'm legally required to howl.", "*chases a squirrel into the next zone*"},
    Cat = {"I knocked your hearthstone off a table. Not sorry.", "If I fits, I sits. Your bag. I fits.", "*stares at nothing for three minutes*"},
    Bear = {"Hibernation is just a long AFK. Can we?", "Honey. Do you have honey. Anyone?", "*scratches back on a tree, sighs deeply*"},
    Boar = {"I'm not fat, I'm armored.", "*rolls in mud, looks proud*", "I just want to charge something. Anything."},
    Spider = {"I made you a web. It's in your bags now.", "Eight eyes and I still can't find the quest item.", "*clicks mandibles thoughtfully*"},
    Raptor = {"Clever girl? No. Clever pet.", "Can we go back to Stranglethorn? I miss the screaming.", "*tilts head suspiciously*"},
    Bat = {"Is it night yet? I'm a night person.", "*hangs upside down from nothing*", "Echolocation says: there's a rare over there."},
    Owl = {"Hoo? You. It's always you.", "*swivels head all the way around, just to flex*", "I know things. Owl things."},
    Crab = {"Sideways is the only way.", "*clacks at a passing murloc*", "Don't call me crabby. I'm always like this."},
    Gorilla = {"I could do this whole zone with one arm.", "*beats chest for no reason*", "Bananas. Just saying the word. Bananas."},
    Turtle = {"Slow and steady wins the... wait, where'd everyone go?", "*retreats into shell, emerges, retreats again*", "I'm basically a tank. A slow tank."},
    Crocolisk = {"I've been told I have a lovely smile.", "*snaps at a butterfly, misses*", "Swim break? Swim break."},
    Hyena = {"Hehehe. Nothing's funny. Hehehe.", "*cackles at your armor choices*", "I found a bone. It's yours now. Or mine."},
    Scorpid = {"I'm not poisonous. I'm spicy.", "*waves stinger menacingly at a rabbit*", "Pinch first, ask questions never."},
    ["Carrion Bird"] = {"Is that guy dying? Asking for a friend.", "*circles above something dead*", "I call dibs on the next corpse."},
    ["Wind Serpent"] = {"I'm technically a noodle with wings.", "*crackles with static, zaps your hair*", "Lightning Breath? More like Lightning Breakfast."},
    Tallstrider = {"My legs are fine. They're just long.", "*high-steps through the grass*", "Mulgore misses me. I can feel it."},
}
