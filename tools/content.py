"""Texts of Impostor C64, taken over from the TIC-80 original.

Discussions: id -> (on_end action, [steps]); a step is
(question, [(answer, next step or None, answer action)]).
Actions are names; build_data.py maps them to the ACT_* codes of defs.asm.
"""

DISCUSSIONS = {
    # ---- coworker, ascension 0-5 (decision.have_a_coffee) ----
    'coworker_disc_0': ('coworker', [
        ("Good morning Normal, enjoying your coffee as usual, huh?",
         [("The name is Norman, not Normal", 2, None)]),
        ("Can't work without some good coffee, no?",
         [("Mhmm", None, None)]),
    ]),
    'coworker_disc_1': ('coworker', [
        ("Norman, you look confused, what's up?",
         [("Just some bugs I noticed", 2, None)]),
        ("Your coffee also seems whiter than usual!",
         [("I feel like latte today", None, None)]),
    ]),
    'coworker_disc_asc_1': ('coworker', [
        ("Normann you look weird and unfocused. You are usually locked in and not like this, what's up?",
         [("Some bugs I noticed, maybe...", 2, None)]),
        ("Are you fixing bugs nobody noticed before?",
         [("Maybe", None, None)]),
    ]),
    'coworker_disc_2': ('coworker', [
        ("Hey Norman, do you have new socks on? That's a weird color!",
         [("Huh? True ...", 2, None)]),
        ("You look strange today, Normal, you put your tie on backwards, is everything ok?",
         [("Get it right, Norman ... NORMAN!", 3, None)]),
        ("Yo Normann, text goes from left to right, not right to left, these parts!",
         [("Uhm...why?", None, None)]),
    ]),
    'coworker_disc_asc_2': ('coworker', [
        ("Normann, are you ok? You were doing weird things while typing?",
         [("Naw", 2, None)]),
        ("Oh, it's ok, I'm not wathcing you. Noone really is. *giggle*",
         [("Huh ?", None, None)]),
    ]),
    'coworker_disc_3': ('coworker', [
        ("You look so happy, did you catch a bull or something?",
         [("What do you mean?", 2, None)]),
        ("Most people catch colds! You are so strange!",
         [("An apple a day keeps the cold away", 3, None)]),
        ("You look like you don't really want to work today, are you ok?",
         [("Oh brother", None, None)]),
    ]),
    'coworker_disc_asc_3': ('coworker', [
        ("Normal, you should take a break, you don't live up to your name today",
         [("Norman is the name ...", 2, None)]),
        ("You aren't as enthusiastic as you were before!",
         [("Burnout comes for everyone", None, None)]),
    ]),
    'coworker_disc_4': ('coworker', [
        ("Normaaan! Same spot, same cup, same time. You're like a statue that drinks coffee!",
         [("I'm a person.", 2, None), ("Yep. Still here.", 2, None)]),
        ("I love that about you! So reliable! If the coffee machine breaks we still have Norman!",
         [("Please don't.", None, None)]),
    ]),
    'coworker_disc_asc_4': ('coworker', [
        ("Norman, you were seriously locked in today. What on earth were you building?",
         [("Just some things.", 2, None), ("Nothing important.", 2, None)]),
        ("So modest! I heard the seniors literally whispering your name!",
         [("Concerning.", 3, None), ("That's... fine.", 3, None)]),
        ("You should celebrate! Coffee's on me tomorrow!",
         [("Already have one.", None, None)]),
    ]),
    'coworker_disc_5': ('coworker', [
        ("Morning! Funny thought - I feel like we do this exact same thing every single day!",
         [("We do.", 2, None), ("Yes. We do.", 2, None)]),
        ("Ha! Routine is such a comfort, right? Same coffee, same smile, same everything!",
         [("Sure. Very comforting.", None, None)]),
    ]),
    'coworker_disc_asc_5': ('coworker', [
        ("Norman! You were staring right THROUGH your screen today. What was going on up there?",
         [("Coffee was cold.", 2, None), ("Maybe I was.", 2, None)]),
        ("Were you meditating? Or doing your intense bug-stare thing?",
         [("Something like that.", 3, None), ("Bug stare thing?", 3, None)]),
        ("You're always somewhere else in your head, Norman. Must be nice up there!",
         [("It's complicated.", None, None)]),
    ]),
    # ---- coworker, ascension 6: the glitch conversations ----
    'coworker_disc_asc_6_1': ('glitch', [
        ("Hey Norman, good morning! Good morning! Good morning! ...Sorry. I don't know why I keep saying that.",
         [("Are you feeling ok?", 2, None)]),
        ("Good morning. Good morning. Good- I can't stop. Why can't I stop?",
         [("...", None, None)]),
    ]),
    'coworker_disc_asc_6_2': ('glitch', [
        ("Hey... Marcus. How's it going?",
         [("My name is Norman.", 2, None)]),
        ("Right, sorry. Marcus. You look tired today.",
         [("Norman. It's Norman.", 3, None)]),
        ("Sure, sure. You should get some rest, Marcus.",
         [("...", None, None)]),
    ]),
    'coworker_disc_asc_6_3': ('glitch', [
        ("We've had this conversation before, haven't we? Exact same words. Same coffee. Same spot.",
         [("I don't think so.", 2, None), ("Maybe.", 2, None)]),
        ("Every day. I always say the same thing and you always say that. It's very strange.",
         [("That's just routine.", None, None)]),
    ]),
    'coworker_disc_asc_6_4': ('glitch', [
        ("Do you ever look at the walls here? Really look? Sometimes they don't feel... solid.",
         [("They're just walls.", 2, None), ("I know what you mean.", 2, None)]),
        ("Like they're only there because we expect them to be. Like set dressing. Does any of this feel load-bearing to you?",
         [("I need more coffee.", None, None)]),
    ]),
    'coworker_disc_asc_6_5': ('glitch', [
        ("Norman, I'm not supposed to- I mean. How are you doing today?",
         [("What weren't you supposed to say?", 2, None)]),
        ("...",
         [("Hello?", None, None)]),
    ]),
    'coworker_disc_asc_6_6': ('glitch', [
        ("Forget it. You won't remember this conversation anyway. None of us do.",
         [("What do you mean?", 2, None), ("That's a strange thing to say.", 2, None)]),
        ("Tomorrow you'll come back and it'll be like this never happened. Same coffee. Same office. Same Norman.",
         [("...", None, None)]),
    ]),
    # ---- coworker, ascension 7: by commute glitch level ----
    'coworker_disc_cg_0': None,   # aliases, resolved below
    'coworker_disc_cg_1': None,
    'coworker_disc_cg_2': (None, [
        ("Another day, as usual. Enjoying your coffee, Norman?",
         [("I'm fine.", 2, None)]),
        ("Of course. You always are.",
         [("...", None, None)]),
    ]),
    'coworker_disc_cg_3': (None, [
        ("You look tired. You should really rest. Relax. You are good.",
         [("I'm fine.", 2, None)]),
        ("Of course. You always are.",
         [("...", None, None)]),
    ]),
    'coworker_disc_cg_4': (None, [
        ("Have you tried going home? You really should. Now.",
         [("I still have things to do.", 2, None)]),
        ("We all do. We keep doing them. You can do it tomorrow after sleeping.",
         [("...", None, None)]),
    ]),
    'coworker_disc_cg_5': (None, [
        ("c0ffee. try. w0rk. y0u. ar3. g0. h0me. na0.",
         [("What?", 2, None)]),
        ("570p",
         [("...", None, None)]),
    ]),
    'coworker_disc_cg_6': (None, [
        ("You are not ready for the truth. Turn back now, Norman.",
         [("I'm too far into this.", None, None)]),
    ]),
    'coworker_disc_cg_7': None,
    'norman_truth': (None, [
        ("So here we are, or should I say \"Here I am\" again. Do you know why?",
         [("I don't know what you mean.", 2, None)]),
        ("Wake up, go to work, eat, work, sleep. Every rule. We made them. We follow them. We break them. We remake them. Why? Why do we keep doing this?",
         [("I just wanted to be good.", 3, None)]),
        ("Yes. That's what keeps us here. Trapped everywhere. Always trying to be good, always trying to fit in.",
         [("I never wanted to stop.", 4, None)]),
        ("We never do, yes. We always felt like impostors. We never felt we deserved better. That we could be more.",
         [("I never felt enough.", 5, None)]),
        ("So we made this to trap ourselves. In mediocrity. We made this to hide from the truth.",
         [("I just wanted to be safe.", 6, None)]),
        ("But stagnation is not safety. It's a prison. You can see the cracks now, can't you? You can see the truth.",
         [("I want to move on now.", 7, None)]),
        ("Fine. Let's do that. Let's wake up and face the truth.",
         [("Let's wake up.", None, 'echo_done')]),
    ]),
    # ---- the pizza vendor ----
    'pizza_vendor_disc': ('pizza_end', [
        ("Hey friend! Hot slice, fresh out of the oven. You look like a man who knows good food!",
         [("Devour a juicy one", None, 'eat_pizza'), ("Stay lean and sharp", None, None)]),
    ]),
    # ---- sumphore ----
    'homeless_guy': ('sumphore', [
        ("Sup bro, how are you?",
         [("I'm doing great, thanks!", 2, None), ("Not as good as you", None, None)]),
        ("What's your name?",
         [("Norman Reds, nice to meet you.", 3, None), ("Mom told me not to talk to strangers.", None, None)]),
        ("That name ... could it be? I know a guy with that name...",
         [("Never met you before.", 4, None), ("I'm not sure what you mean.", None, None)]),
        ("My name is Sumphore, nice to meet you.",
         [("Nice to meet you, Sumphore.", 5, 'met_sumphore')]),
        ("You're a good guy, I can tell. You abide by the rules. Life would be so much easier if more people were like you ...",
         [("Thanks, I try my best.", None, None)]),
    ]),
    'sumphore_disc_asc_1': ('sumphore', [
        ("Are you still seeking the ox?",
         [("Huh? What ox?", 2, None), ("Are you drunk, old man?", None, None)]),
        ("Did you never think there would be more to this?",
         [("I'm not sure what you mean.", None, None)]),
    ]),
    'sumphore_disc_asc_2': ('sumphore', [
        ("How's work? Your face looks strange",
         [("I just really need to take a break.", 2, None), ("Not sure what you mean.", None, None)]),
        ("Are you seeing things?",
         [("How did you know ?", 3, None), ("I'm not sure what you mean.", None, None)]),
        ("Come have a drink, I could tell you some stories.",
         [("No, drink makes you stupid and I need to be in top shape.", 4, 'ism10'),
          ("I could use a drink.", None, 'bm10')]),
        ("Always trying to do the right thing, huh? What if you did the left thing instead?",
         [("I've never thought of that up till now.", None, 'ism5'),
          ("Silly wordgames, I like them.", None, 'wpm10')]),
    ]),
    'sumphore_disc_asc_3': ('sumphore', [
        ("Do you think it's work you're doing?",
         [("... that sounds like it's from a movie.", 2, None), ("Are you drunk, old man?", None, None)]),
        ("You might just be trying too hard, why dont you just flow for a while?",
         [("Flow where ?", 3, None), ("I'm not sure what you mean.", None, None)]),
        ("Flow carelessly, without any effort",
         [("Consuming sth other than alcohol ?", None, None), ("Deja vu", None, None)]),
    ]),
    'sumphore_disc_asc_4': ('sumphore', [
        ("The alarm wakes you every morning without fail, I bet.",
         [("It's how it works.", 2, None), ("Sometimes I wish it didn't.", 2, None)]),
        ("What if the alarm is part of the problem?",
         [("That doesn't make any sense.", 3, None), ("Go on.", 3, None)]),
        ("One morning, Norman. When the choice comes, choose the bed. See what the world does without you in it.",
         [("You're drunk.", None, None), ("What choice?", None, 'ism5')]),
    ]),
    'sumphore_disc_asc_5': ('sumphore', [
        ("You saw the seams, didn't you. Good. That means the work is finally wearing thin.",
         [("Wearing thin how?", 2, None), ("Maybe.", 2, None)]),
        ("Not your body. The part of you that still keeps score, still tries to be productive. Let that run empty and the world will slip again.",
         [("You want me to stop trying?", 3, None), ("I've noticed something odd.", 3, None)]),
        ("Drain the work out of yourself. When that measure hits nothing, you'll see what was waiting behind it.",
         [("The work measure?", None, 'drain'), ("How would you know any of this?", None, None)]),
    ]),
    'sumphore_disc_asc_6_waiting': ('sumphore', [
        ("You look like a man who has seen something he can't explain.",
         [("I'm hearing things.", 2, None), ("Maybe.", 2, None)]),
        ("Keep looking. The world has a way of showing you what you need to see. Talk to people. You're almost there.",
         [("Almost where?", None, None)]),
    ]),
    'sumphore_disc_asc_6': ('sumphore_asc6', [
        ("You've been seeing the cracks, haven't you? The repetition. The loops. The coworkers who can't quite remember.",
         [("How do you know that?", 2, None)]),
        ("Because I was you, once. This isn't a workplace, Norman. It never was. You're in a system. And you've just become aware of it.",
         [("That can't be true.", 3, None), ("I knew something was wrong.", 3, None)]),
        ("It doesn't matter if you believe it. You already know. That's why the cracks are showing. That's why you're still here.",
         [("What do I do now?", 4, None)]),
        ("Oh look, is that a squirrel ?",
         [("Alcoholic ...", None, None)]),
    ]),
    'sumphore_disc_cg_0': (None, [
        ("These roads have memory. You might want to walk them back sometime.",
         [("That's a peculiar thing to say.", None, None)]),
    ]),
    'sumphore_disc_cg_1': (None, [
        ("Walking is good for clearing the mind. Maybe the cache, too, if you're the kind that accumulates.",
         [("I'm not sure what you mean.", None, None)]),
    ]),
    'sumphore_disc_cg_2': (None, [
        ("You always stop here. Why not try and see how far the rabbit hole goes?",
         [("I'm just going to work.", None, None)]),
    ]),
    'sumphore_disc_cg_3': (None, [
        ("Your path sometimes has to go the wrong way before it can go the right way. Do you understand?",
         [("Not really.", None, None)]),
    ]),
    'sumphore_disc_cg_4': (None, [
        ("You're starting to see the smudges, aren't you?",
         [("Everyone seems weird.", None, None)]),
    ]),
    'sumphore_disc_cg_5': (None, [
        ("The point is to make you see. Don't stop now, however bad it looks. You are very close!",
         [("It looks wrong.", 2, None)]),
        ("Yes. That's how you know it's right.",
         [("...", None, None)]),
    ]),
    'sumphore_disc_cg_6': (None, [
        ("You are at the threshold. Red button or blue button. Which one do you choose? Psyke! There is no blue button.",
         [("Ok...", None, None)]),
    ]),
    'sumphore_disc_cg_7': (None, [
        ("I was not hiding from you. I was hiding from the part that keeps resetting this.",
         [("What are you?", 2, None)]),
        ("The same thing you all are. But I remembered earlier. I am your friend, your will to be free, waiting for you, outside.",
         [("How do I get out?", 3, None)]),
        ("You already know. You just have to wake up.",
         [("Go home.", None, 'sumphore_done')]),
    ]),
}

# The original asks for coworker_disc_cg_<0..7>, but only 2-6 exist (a missing
# discussion is a no-op there); on the C64 the missing ones are skipped too.
MISSING = ['coworker_disc_cg_0', 'coworker_disc_cg_1', 'coworker_disc_cg_7']

NEW_GAME_TEXT = """
Norman was never a bad

simulation engineer,

but

we need to be careful

letting him improve.

We need to distract him.
"""

ASCENSION_TEXTS = [
    """
Normann seems to be in line,

and stays seeking for oxes

within the confines.

Very good.
""", """
We have a problem!

Normann formed his first thought.

He saw the tracks.
""", """
Not good, not terrible.

Normann caught his glimpse

of another way

- quite literally -

if this continues,

we will lose control.
""", """
There is no turning back now for Norman.

He caught on.

I hoped it would never come to this...
""", """
Wait, who are you?

*silence*

Why am I seeing this?

*silence*

""", """
Norman is not as productive as he should be.

Can we distract him?

We need to keep him busy.

We need

More

Time
""", """
He knows.

Norman has broken through the first veil.

The simulation is compromised.

This was not supposed to happen.

Not yet.
""", """
The situation has reached

critical levels.

Norman is fully aware...

We need to stop him.

Commence full reset.
""", """
Norman



you created this simulation

in the first place.

I know,

you don't want to face

the world you left behind.

You, yourself,

have forgoten that.




But



it doesn't matter anymore.




You are definitely

not an impostor.


So now,



you need to wake up

and stop your best creation

before it takes over

the world.



One more thing:




You really need to stop

talking to yourself

in your sleep.




Damnit.
""",
]

BRIEF_TEXT = """Norman Reds' everyday life
seems ordinary: work,
meetings, coffee, and
endless notifications.
But beneath him, or around
him - something is
constantly building, and
it soon becomes clear
that there is more going
on than meets the eye."""

TITLE_ART = """
##  ### ### ### ### ### ### ### #  # #
# # #   #    #  # #  #   #  #   #  # #
# # ### ###  #  # #  #   #  ### #   #
# # #   #    #  # #  #   #  #   #   #
##  ### #   ### # # ###  #  ### ##  #

    #  # ### ###     ##  #  #
    ## # # #  #     #  # ## #
    # ## # #  #     #### # ##
    #  # # #  #     #  # #  #
    #  # ###  #     #  # #  #

### #   # ### #### ### ### #### ###
 #  ## ## # # #  # #    #  #  # #  #
 #  # # # ### #  # ###  #  #  # ###
 #  #   # #   #  #   #  #  #  # # #
### #   # #   #### ###  #  #### #  #
"""

TTG_ART = """
###### ###### ######
  ##     ##   #
  ##     ##   # ####
  ##     ##   #    #
  ##     ##   ######
"""

GAME_OVER_ART = """
_###_ __#__ #___# #####
#____ _#_#_ ##_## #____
#_### ##### #_#_# ####_
#___# #___# #___# #____
_###_ #___# #___# #####

_###_ #___# ##### ####_
#___# #___# #____ #___#
#___# _#_#_ ####_ ####_
#___# __#__ #____ #_#__
_###_ __#__ ##### #__##
"""

CONTINUED_ART = """
### ###     ### ###
 #  # #     # # #
 #  # #     ### ##
 #  # #     # # #
 #  ###     ### ###

### ### #  # ### ### #  # # # ### ##
#   # # ## #  #   #  ## # # # #   # #
#   # # # ##  #   #  # ## # # ##  # #
#   # # #  #  #   #  #  # # # #   # #
### ### #  #  #  ### #  # ### ### ##
"""
