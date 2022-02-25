/*
+crew
+crew <name> (staff-only)
+crew/<page> - view a  page of the crew's sheet
+crew/<page> <player> (staff-only)

Crew chargen:

+crew/create <crew>
+crew/channel <channel>
+crew/channel <player>=<channel> (staff-only)
+crew/lock

+cohorts
+cohort/create <name>=<type>
+cohort/create <player>/<name>=<type>
+cohort/destroy <name>=<type>
+cohort/destroy <player>/<name>=<type>
+cohort/edit <name>
+cohort/edit <player>/<name>
+cohort/set <stat>=<value>
+cohort/add <stat>=<value>
+cohort/remove <stat>=<value>

+factions
+factions <player>
+faction/log
+faction/log <player>
+faction/set <type>=<faction>
+faction/set <player>/<type>=<faction>
+faction/pay <type>=<#>
+faction/pay <player>/<type>=<#>
+faction/boost
+faction/boost <player>
+faction/unboost
+faction/unboost <player>

Post-CG crew commands:

+crew/join <crew>
+crew/invite <player>
+crew/boot <player>
+crew/leave
* +crew/transfer <player>
* +crew/transfer <playerA>=<playerB> (staff-only)

Someday:
*	+crew/vote <boot or invite>=<player>
*	+crew/yes <player>=<boot or invite>
*	+crew/no <player>=<boot or invite>

+faction/set <player>/<faction>=<#>
+claim/award <player>=<name or map number>

Staff commands:

* +crew/unlock <player>
* +crew/approve <player>
* +crew/unapprove <player>

TODO: Code to raise a crew's tier.

*/

@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@
@@ Aliases
@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@

&c.+crew [v(d.cg)]=$+crew*:@break switch(%0, /*, 1, * *, 1, 0); @force %#=+sheet/crew%0;

&c.+cohort/del [v(d.cg)]=$+cohort/del*:@force %#=+cohort/remove [switch(%0, %b*, trim(%0), rest(%0))];

&c.+cohort/rem [v(d.cg)]=$+cohort/rem*:@break strmatch(%0, ove *); @force %#=+cohort/remove [switch(%0, %b*, trim(%0), rest(%0))];

&c.+fact [v(d.cg)]=$+fact*: @break cand(strmatch(%0, ions*), not(strmatch(%0, ions/*))); @break strmatch(%0, ion/log*); @break switch(%0, /log*, 1, ions/log*, 1, 0)={ @force %#=+faction/log [switch(%0, %b*, trim(%0), rest(%0))]; }; @break strmatch(%0, ion/*); @force %#=+factions [switch(%0, %b*, trim(%0), rest(%0))];

@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@
@@ View crew sheet
@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@

&c.+crew_player [v(d.cg)]=$+crew *:@force %#=+sheet/crew %0;

&c.+crew_all [v(d.cg)]=$+crew/all:@pemit %#=ulocal(layout.crew1, %#, %#); @pemit %#=ulocal(layout.subsection, crew2, %#, %#); @assert hasattr(%#, _stat.crew_locked)={ @pemit %#=strcat(%r, ulocal(layout.crew-cg-errors, %#, %#)); };

&c.+crew_all_player [v(d.cg)]=$+crew/all *: @assert isstaff(%#)={ @trigger me/tr.error=%#, You must be staff to view someone else's sheet.; }; @assert t(setr(P, ulocal(f.find-player, %0, %#)))={ @trigger me/tr.error=%#, Could not find a player named '%0'.; }; @pemit %#=ulocal(layout.crew1, %qP, %#); @pemit %#=ulocal(layout.subsection, crew2, %qP, %#); @assert hasattr(%qP, _stat.crew_locked)={ @pemit %#=strcat(%r, ulocal(layout.crew-cg-errors, %qP, %#)); };

&c.+crew_page [v(d.cg)]=$+crew/*:@break cand(isstaff(%#), strmatch(%0, * *)); @break t(finditem(all|create|join|boot|leave|invite|transfer|lock|unlock|channel, first(%0), |)); @eval setq(V, if(member(1 2, %0), page%0, %0)); @assert t(setr(S, finditem(setr(L, xget(%vD, d.crew-sheet-sections)), %qV, |)))={ @trigger me/tr.error=%#, Could not find the section of the crew sheet starting with '%0'. Valid sections are 'all' or: [itemize(%qL, |)].; }; @eval setq(S, ulocal(f.get-stat-location, %qS)); @pemit %#=ulocal(layout.subsection, if(hasattrp(me, layout.crew-%qS), crew-%qS, %qS), %#, %#);

&c.+crew_page_player [v(d.cg)]=$+crew/* *:@break t(finditem(all|create|join|boot|leave|invite|transfer|lock|unlock|channel, first(%0), |)); @assert isstaff(%#)={ @trigger me/tr.error=%#, You must be staff to view someone else's sheet.; }; @assert t(setr(P, ulocal(f.find-player, %1, %#)))={ @trigger me/tr.error=%#, Could not find a player named '%1'.; }; @eval setq(V, if(member(1 2, %0), page%0, %0)); @assert t(setr(S, finditem(setr(L, xget(%vD, d.crew-sheet-sections)), %qV, |)))={ @trigger me/tr.error=%#, Could not find the section of the crew sheet starting with '%0'. Valid sections are 'all' or: [itemize(%qL, |)].; }; @eval setq(S, ulocal(f.get-stat-location, %qS)); @pemit %#=ulocal(layout.subsection, if(hasattrp(me, layout.crew-%qS), crew-%qS, %qS), %qP, %#);

@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@
@@ Create a crew
@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@

&c.+crew/create [v(d.cg)]=$+crew/create *:@break strmatch(%0, *=*); @assert not(isapproved(%#))={ @trigger me/tr.error=%#, You must be unapproved to create a new crew. Open a new +request to get unapproved and start working on it.; }; @assert cor(not(setr(C, ulocal(f.get-player-stat, %#, crew object))), t(member(%qC, %#)), gettimer(%#, crew.new, if(strmatch(%0, *=*), if(t(rest(%0, =)), rest(%0, =), NO), NO)))={ @trigger me/tr.message=%#, This will take you out of your existing crew%, [ulocal(f.get-player-stat, %qC, Crew Name)]. If you're sure you want to proceed%, type '+crew/create %0=YES' within the next 15 minutes. The time is now [prettytime()].; @eval settimer(%#, crew.new, 900, YES); }; @set %#=[ulocal(f.get-stat-location-on-player, crew object)]:%#; @set %#=[ulocal(f.get-stat-location-on-player, crew name)]:%0; @set %#=[ulocal(f.get-next-id-attr, %#, _crew-join-%#-)]:[prettytime()]; @trigger me/tr.success=%#, You have started a new crew called '%0'.;

@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@
@@ Join a crew
@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@

&c.+crew/join [v(d.cg)]=$+crew/join *:@break strmatch(%0, *=*); @eval setq(R, search(EPLAYER=cand(t(member(ulocal(f.get-player-stat, ##, crew object), ##)), strmatch(ulocal(f.get-player-stat, ##, crew name), %0*)))); @assert t(%qR)={ @trigger me/tr.error=%#, Couldn't find a crew named '%0'.; }; @assert eq(words(%qR), 1)={ @trigger me/tr.error=%#, There are multiple crews that start with '%0': [itemize(iter(%qR, ulocal(f.get-player-stat, itext(0), crew name),, |), |)].; }; @eval setq(T, xget(%vD, d.crew-invitation-time)); @assert t(gettimer(%#, crew.invite-%qR))={ @trigger me/tr.error=%#, You have not been invited to join that crew within the last [secs2hrs(%qT)]. Message [ulocal(f.get-name, %qR, %#)] for an invitation.; }; @assert not(member(setr(C, ulocal(f.get-player-stat, %#, crew object)), %#))={ @assert not(t(setdiff(ulocal(f.get-crew-members, %qC), %#)))={ @trigger me/tr.error=%#, You have existing crew members. Before you can join another crew%, you need to %ch+crew\/transfer <player>%cn control of your current crew to someone else.; }; @assert gettimer(%#, crew.join, if(strmatch(%0, *=*), if(t(rest(%0, =)), rest(%0, =), NO), NO))={ @trigger me/tr.message=%#, This will take you out of your existing crew%, [ulocal(f.get-player-stat, %qC, Crew Name)]. If you're sure you want to proceed%, type '+crew/join %0=YES' within the next 15 minutes. The time is now [prettytime()].; @eval settimer(%#, crew.join, 900, YES); }; }; @set %#=[ulocal(f.get-stat-location-on-player, crew object)]:%qR; @set %#=[ulocal(f.get-next-id-attr, %#, _crew-join-%qR-)]:[prettytime()]; @trigger me/tr.success=%#, You have joined the %ch[ulocal(f.get-player-stat, %qR, crew name)]%cn crew.; @trigger me/tr.crew-emit=%qR, ulocal(f.get-name, %#) joined the crew.; @trigger me/tr.crew-channel-invite=%#, %qR;

@@ %0: player to invite
@@ %1: crew object
&tr.crew-channel-invite [v(d.cg)]=@assert t(setr(C, ulocal(f.get-player-stat, %1, crew channel object))); @break ulocal(filter.is-on-channel, %qC, %0); @eval setr(N, ulocal(%vH/f.get-channel-name, %qC)); @if strmatch(ulocal(%vH/f.get-channel-lock, %qC), Password-protected)={ @set %0=_channel-password-%qC:[ulocal(%vH/f.get-channel-password, %qC)]; @trigger me/tr.success=%0, cat(You have been granted a key to the crew channel%, %qN.); }; @wait .1=@trigger me/tr.success=%0, cat(Please join the crew channel%, %qN%, by typing, ansi(h, ulocal(%vH/f.get-channel-alias, %qC)/on).);

@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@
@@ Boot someone out of the crew
@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@

&c.+crew/boot [v(d.cg)]=$+crew/boot *:@eval setq(C, ulocal(f.get-player-stat, %#, crew object)); @assert ulocal(f.is-full-member, %#, %qC)={ @trigger me/tr.error=%#, You must be a full member of the crew in order to perform boots. You can ask staff to intervene with %chreq/social <title>=<problem>%cn.; }; @assert t(setr(P, ulocal(f.find-player, %0, %#)))={ @trigger me/tr.error=%#, Could not find a player named '%0'.; }; @eval setq(N, ulocal(f.get-name, %qP, %#)); @assert t(setinter(ulocal(f.get-crew-members, %qC), %qP))={ @trigger me/tr.error=%#, %qN is not a member of [ulocal(f.get-crew-name, %qC)].; }; @assert cor(ulocal(f.is-probationary-member, %qP, %qC), ulocal(f.is-idle-member, %qP, %qC), not(ulocal(f.is-crew-approved, %qC)))={ @trigger me/tr.error=%#, %qN is an active full member of your crew and cannot be booted without staff assistance. Please reach out to staff with %chreq/social <title>=<problem>%cn.; }; @assert gettimer(%#, boot-%qP)={ @trigger me/tr.message=%#, You are about to boot %qN. This will remove them from your crew until someone invites them to return. Are you sure? If yes%, type %ch+crew/boot %qN%cn again within the next 10 minutes. The time is now [prettytime()].; @eval settimer(%#, boot-%qP, 600); }; @set %qP=ulocal(f.get-stat-location-on-player, crew object):; @trigger me/tr.crew-emit=cat(ulocal(f.get-name, %#), booted, ulocal(f.get-name, %qP) from the crew.); @trigger me/tr.success=%#, You have booted %qN from your crew.; @trigger me/tr.message=%qP, ulocal(f.get-name, %#, %qP) booted you out of [ulocal(f.get-crew-name, %qC)].;

@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@
@@ Leave a crew
@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@

&c.+crew/leave [v(d.cg)]=$+crew/leave:@assert t(setr(C, ulocal(f.get-player-stat, %#, crew object)))={ @trigger me/tr.error=%#, You don't appear to be in a crew.; }; @assert not(isapproved(%#))={ @trigger me/tr.error=%#, You're already approved and can't leave your crew without staff assistance. Please reach out to staff with %chreq/social <title>=<problem>%cn. Alternately%, you can try joining a new crew.; }; @set %#=ulocal(f.get-stat-location-on-player, crew object):; @trigger me/tr.success=%#, You have left your old crew.; @trigger me/tr.crew-emit=%qC, ulocal(f.get-name, %#) has left the crew.;

@@ TODO: Consider force-booting them off the crew channel?

@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@
@@ Invite someone into the crew
@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@

@@ TODO: See about making it so that ALL players who are non-probies have the power to invite new players.

&layout.crew-invitation [v(d.cgf)]=cat(You have been invited to join, setr(0, ulocal(f.get-player-stat, %0, crew name)), by, ulocal(f.get-name, %0, %1)., To accept this invitation%, type %ch+crew/join %q0., This invitation is good for, secs2hrs(xget(%vD, d.crew-invitation-time)).)

&c.+crew/invite [v(d.cg)]=$+crew/invite *:@eval setq(C, ulocal(f.get-player-stat, %#, crew object)); @assert t(%qC)={ @trigger me/tr.error=%#, You don't currently have a crew set up. +crew/create <name> to start one.; }; @assert t(member(%qC, %#))={ @trigger me/tr.error=%#, You must be the crew's statter in order to invite people. Message [ulocal(f.get-name, %qR, %#)] to issue the invitation.; }; @assert t(setr(P, ulocal(f.find-player, %0, %#)))={ @trigger me/tr.error=%#, Could not find a player named '%0'.; }; @eval setq(N, ulocal(f.get-name, %qP, %#)); @assert not(t(setinter(ulocal(f.get-crew-members, %qC), %qP)))={ @trigger me/tr.error=%#, %qN is already a member of [ulocal(f.get-player-stat, %qC, crew name)].; }; @eval settimer(%qP, crew.invite-%qC, setr(D, xget(%vD, d.crew-invitation-time))); @trigger me/tr.success=%#, You have issued an invitation to %qN to join [ulocal(f.get-player-stat, %qC, crew name)]. This invitation is good for [secs2hrs(%qD)].; @trigger me/tr.crew-emit=%qC, cat(ulocal(f.get-name, %#) invited, ulocal(f.get-name, %qP) to join the crew.); @break t(member(xget(%vD, d.message-method), msg))={ @set %#=msg-send-crew_invitation:[default(%#/msg-send-crew_invitation, xget(%vD, d.crew_invitation_flair))]; @trigger me/tr.msg-player=crew_invitation, %qP=:sends: [ulocal(layout.crew-invitation, %qC, %qP)], %#; }; @assert andflags(%qP, C!D)={ @mail/quick %qP/Crew Invitation: [ulocal(f.get-player-stat, %qC, crew name)]=[ulocal(layout.crew-invitation, %0, %qP)]; }; @trigger me/tr.pemit=%qP, ulocal(layout.crew-invitation, %0, %qP), %#;

@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@
@@ Crew transfers
@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@

@@ TODO: Make sure to scan all invited players to ensure their invitations get transferred as well.

&c.+crew/transfer [v(d.cg)]=$+crew/transfer *:@break strmatch(%0, *=*); @pemit %#=Crew owner transfers ownership of the crew to someone else.;
+crew/transfer asdf

&c.+crew/transfer_staff [v(d.cg)]=$+crew/transfer *=*: think Staff transfers ownership of a crew to someone else.; @trigger me/tr.success=%#, ;

@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@
@@ Crew locking
@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@

&layout.hunting [v(d.cgf)]=if(t(setr(F, ulocal(f.get-player-stat, %0, faction.hunting))), strcat(first(%qF, |): This faction claims the crew's hunting ground. The crew paid, %b, rest(%qF, |), %b, coin to keep them happy%, resulting in a status of, %b, ulocal(f.get-faction-status, %qC, first(%qF, |)).))

&layout.helped [v(d.cgf)]=if(t(setr(F, ulocal(f.get-player-stat, %0, faction.helped))), strcat(first(%qF, |): This faction helped the crew gain an Upgrade. The crew paid, %b, rest(%qF, |), %b, coin to thank them%, resulting in a status of, %b, ulocal(f.get-faction-status, %qC, first(%qF, |)).))

&layout.harmed [v(d.cgf)]=if(t(setr(F, ulocal(f.get-player-stat, %0, faction.harmed))), strcat(first(%qF, |): This faction was harmed when the crew got an Upgrade. The crew paid, %b, rest(%qF, |), %b, coin to pacify them%, resulting in a status of, %b, ulocal(f.get-faction-status, %qC, first(%qF, |)).))

&layout.friendly [v(d.cgf)]=if(t(setr(F, ulocal(f.get-player-stat, %0, faction.friendly))), strcat(first(%qF, |): This faction is, if(t(rest(%qF, |)), strcat(%b, extremely)), %b, friendly to the crew's Favorite Contact%, resulting in a status of, %b, ulocal(f.get-faction-status, %qC, first(%qF, |)).))

&layout.unfriendly [v(d.cgf)]=if(t(setr(F, ulocal(f.get-player-stat, %0, faction.unfriendly))), strcat(first(%qF, |): This faction is, if(t(rest(%qF, |)), strcat(%b, extremely)), %b,  unfriendly to the crew's Favorite Contact%, resulting in a status of, %b, ulocal(f.get-faction-status, %qC, first(%qF, |)).))

&c.+crew/lock [v(d.cg)]=$+crew/lock:@eval setq(C, ulocal(f.get-player-stat, %#, crew object)); @assert t(%qC)={ @trigger me/tr.error=%#, You don't currently have a crew set up. +crew/create <name> to start one.; }; @assert not(hasattr(%qC, _stat.crew_locked))={ @trigger me/tr.error=%#, Your crew is already locked.; }; @set %qC=_stat.crew_locked:[prettytime()]; @dolist/delimit | [xget(%vD, d.crew-stats-that-default)]={ @set %qC=[ulocal(f.get-stat-location-on-player, ##)]:[ulocal(f.get-player-stat, %qC, ##)]; }; @set %qC=ulocal(f.get-stat-location-on-player, crew coin):[sub(2, ulocal(f.get-total-faction-coin, %qC))]; @set %qC=ulocal(f.get-stat-location-on-player, xp.crew.max):10; @trigger me/tr.log=%qC, _faction-, %#, ulocal(layout.hunting, %qC); @trigger me/tr.log=%#, _faction-, %#, ulocal(layout.helped, %qC); @trigger me/tr.log=%#, _faction-, %#, ulocal(layout.harmed, %qC); @trigger me/tr.log=%#, _faction-, %#, ulocal(layout.friendly, %qC); @trigger me/tr.log=%#, _faction-, %#, ulocal(layout.unfriendly, %qC); @trigger me/tr.success=%#, You locked your crew.; @trigger me/tr.crew-emit=%qC, %N locked the crew for editing. No further changes can be made.;

@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@
@@ Setting up the crew channel
@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@

@@ TODO: see how this works out. It sets the crew channel up ONCE... unless the original no longer exists. If the original gets deleted, the crew can assign a new one. Otherwise, they'll have to ask staff.

&c.+crew/channel [v(d.cg)]=$+crew/channel *:@break strmatch(%0, *=*); @eval setq(C, ulocal(f.get-player-stat, %#, crew object)); @assert t(%qC)={ @trigger me/tr.error=%#, You don't currently have a crew set up. +crew/create <name> to start one.; }; @assert cor(not(t(setr(O, xget(%qC, setr(L, ulocal(f.get-stat-location-on-player, crew channel object)))))), not(isdbref(%qO)))={ @trigger me/tr.error=%#, Your crew already has a crew channel. You'll need to put in a request with staff to change it.; }; @assert not(t(setr(E, u(%vH/f.get-channel-by-name-error, %#, %0, 1))))={ @trigger me/tr.error=%#, %qE; }; @assert ulocal(%vH/f.can-modify-channel, %#, %qN)={ @trigger me/tr.error=%#, You are not in control of %qT%, so you can't set it as your crew channel. Get the channel owner to do it or talk to staff.; }; @set %qC=%qL:%qN; @set %qC=[ulocal(f.get-stat-location-on-player, crew channel name)]:%qT; @trigger me/tr.success=%#, You set your crew's channel to %qT. New players will be prompted to join that channel when they join your crew.; @cemit %qT=%N sets this channel as the designated crew channel for %ch[ulocal(f.get-player-stat, %qC, crew name)]%cn.;

&c.+crew/channel_staff [v(d.cg)]=$+crew/channel *=*:@assert isstaff(%#)={ @trigger me/tr.error=%#, You must be staff to change a crew's channel.; }; @assert t(setr(P, ulocal(f.find-player, %0, %#)))={ @trigger me/tr.error=%#, Could not find a player named '%0'.; }; @eval setq(C, ulocal(f.get-player-stat, %qP, crew object)); @assert t(%qC)={ @trigger me/tr.error=%#, ulocal(f.get-name, %qP, %#) doesn't currently have a crew set up.; }; @assert not(t(setr(E, u(%vH/f.get-channel-by-name-error, %#, %1, 0))))={ @trigger me/tr.error=%#, %qE; }; @assert ulocal(%vH/f.can-modify-channel, %#, %qN)={ @trigger me/tr.error=%#, You are not in control of %qT%, so you can't set it as someone's crew channel.; }; @set %qC=[ulocal(f.get-stat-location-on-player, crew channel object)]:%qN; @set %qC=[ulocal(f.get-stat-location-on-player, crew channel name)]:%qT; @trigger me/tr.success=%#, You set the crew channel for %ch[ulocal(f.get-player-stat, %qC, crew name)]%cn to %qT. New players will be prompted to join that channel when they join the crew.; @cemit %qT=%N sets this channel as the designated crew channel for %ch[ulocal(f.get-player-stat, %qC, crew name)]%cn.;

@@ %0: crew object
@@ %1: what to emit
&tr.crew-emit [v(d.cg)]=@assert t(setr(N, ulocal(f.get-player-stat, %0, crew channel name))); @trigger me/tr.alert-to-channel=%qN, %1;

@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@
@@ +cohorts
@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@

&c.+cohorts [v(d.cg)]=$+cohorts:@pemit %#=ulocal(layout.subsection, crew-cohorts, %#, %#);

@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@
@@ Create cohorts
@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@

&c.+cohort/create [v(d.cg)]=$+cohort/create *=*: @break strmatch(%0, */*);@assert t(setr(C, ulocal(f.get-player-stat, %#, crew object)))={ @trigger me/tr.error=%#, ulocal(layout.crew-object-error, %0, %1, %#, %#); }; @assert t(%0)={ @trigger me/tr.error=%#, You must enter a name for the new cohort.; }; @eval strcat(setq(V, ulocal(f.get-cohort-stat-pretty-value, Types, %1)), setq(T, switch(%1, *s, Gang, V*, Vehicle, Expert))); @assert cand(t(%qV), t(%qT))={ @trigger me/tr.error=%#, Couldn't figure out what kind of cohort to create. Options are: [ulocal(layout.list, ulocal(f.list-cohort-stat-pretty-values, Types))]. If you want to make an Expert instead of a Gang%, leave off the "s" at the end of the type.; }; @trigger me/tr.create-cohort=%0, %qV, %#, %#, %qT;

&c.+cohort/create_staff [v(d.cg)]=$+cohort/create */*=*: @assert isstaff(%#)={ @trigger me/tr.error=%#, You must be staff to create cohorts for players.; }; @assert t(setr(P, ulocal(f.find-player, %0, %#)))={ @trigger me/tr.error=%#, Could not find a player named '%0'.; }; @assert t(setr(C, ulocal(f.get-player-stat, %qP, crew object)))={ @trigger me/tr.error=%#, ulocal(layout.crew-object-error, %0, %1, %qP, %#); }; @assert t(%1)={ @trigger me/tr.error=%#, You must enter a name for the new cohort.; }; @eval strcat(setq(V, ulocal(f.get-cohort-stat-pretty-value, Types, %2)), setq(T, switch(%2, *s, Gang, V*, Vehicle, Expert))); @assert cand(t(%qV), t(%qT))={ @trigger me/tr.error=%#, Couldn't figure out what kind of cohort to create. Options are: [ulocal(layout.list, ulocal(f.list-cohort-stat-pretty-values, Types))]. If you want to make an Expert instead of a Gang%, leave off the "s" at the end of the type.; }; @trigger me/tr.create-cohort=%1, %qV, %qP, %#, %qT;

@@ %0 - name
@@ %1 - type
@@ %2 - player
@@ %3 - player doing the setting
@@ %4 - gang or expert type
&tr.create-cohort [v(d.cg)]=@assert cand(valid(attrname, setr(L, ulocal(f.get-stat-location-on-player, cohort_type.%0))), lte(strlen(%qL), 60))={ @trigger me/tr.error=%3, The name '%0' cannot be translated into a valid attribute name%, which means it won't work. Please change the name or open a job with staff requesting a fix.; }; @assert t(setr(C, ulocal(f.get-player-stat, %2, crew object)))={ @trigger me/tr.error=%3, ulocal(layout.crew-object-error, %0, %1, %2, %3); }; @assert ulocal(f.is-allowed-to-edit-crew, %2, %3)={ @trigger me/tr.error=%3, ulocal(layout.cannot-edit-crew-stats, Cohort, %0, %2, %3); }; @eval setq(T, ulocal(f.count-upgrades, %qC)); @eval setq(A, ulocal(f.is-allowed-to-break-stat-setting-rules, %3, %2)); @assert cor(not(strmatch(%1, Vehicle)), not(t(finditem(iter(ulocal(f.get-player-stat, %0, Cohorts), ulocal(f.get-cohort-stat, %0, itext(0), Cohort Type), |, |), Vehicle, |))), %qA)={ @trigger me/tr.error=%3, Players may only have one Vehicle cohort.; }; @assert cor(not(strmatch(%1, Vehicle)), ulocal(f.has-list-stat, %qC, Crew Abilities, Like Part of the Family), %qA)={ @trigger me/tr.error=%3, Players must have the Crew Ability "Like Part of the Family" to take a Vehicle as a cohort.; }; @assert cor(not(strmatch(%1, Vehicle)), ulocal(f.has-list-stat, %qC, Upgrades, Vehicle), %qA)={ @trigger me/tr.error=%3, You must have the Upgrade "Vehicle" to take a Vehicle as a cohort.; }; @assert cor(lte(add(%qT, 2), 4), strmatch(%1, Vehicle), %qA)={ @trigger me/tr.error=%3, ulocal(layout.cohort-max, %qT, 0, %2, %3); }; @eval setq(E, xget(%2, ulocal(f.get-stat-location-on-player, Cohorts))); @assert not(member(%qE, %1, |))={ @trigger me/tr.error=%3, Player already has the Cohort '%1'.; }; @trigger me/tr.add-or-remove-stat=Cohorts, %0, %qC, %3, 0, Cohort; @set %qC=ulocal(f.get-stat-location-on-player, cohort_type.%0):%4; @set %qC=ulocal(f.get-stat-location-on-player, types.%0):%1; @set %3=_stat.cohort.editing:%qC/%0; @pemit %3=strcat(header(Cohort, %3), %r, multicol(ulocal(layout.cohort, %2, %0), *, 0, |, %3), %r, footer(, %3));

@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@
@@ Destroy cohorts
@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@

&c.+cohort/destroy [v(d.cg)]=$+cohort/destroy *:@break strmatch(%0, */*); @assert t(setr(C, ulocal(f.get-player-stat, %#, crew object)))={ @trigger me/tr.error=%#, ulocal(layout.crew-object-error, %0, %1, %#, %#); }; @assert ulocal(f.is-allowed-to-edit-crew, %#, %#)={ @trigger me/tr.error=%#, You can't edit your crew once it's locked.; }; @assert t(setr(N, ulocal(f.find-cohort, %qC, first(%0, =))))={ @trigger me/tr.error=%#, Could not find a cohort matching '[first(%0, =)]' in your crew.; }; @assert cand(gettimer(%#, cohort-destroy, %qN), match(rest(%0, =), YES))={ @eval settimer(%#, cohort-destroy, 600, %qN); @trigger me/tr.message=%#, This will destroy your cohort '%ch%qN%cn'. If you would like to continue%, type %ch+cohort/destroy %qN=YES%cn within the next 10 minutes. It is now [prettytime()].; }; @wipe %#/_stat.*.[ulocal(f.get-stat-location, %qN)]; @trigger me/tr.add-or-remove-stat=Cohorts, %qN, %qC, %#, 1, Cohort;

&c.+cohort/destroy_staff [v(d.cg)]=$+cohort/destroy */*: @assert isstaff(%#)={ @trigger me/tr.error=%#, You must be staff to destroy a player's cohort.; }; @assert t(setr(P, ulocal(f.find-player, %0, %#)))={ @trigger me/tr.error=%#, Could not find a player named '%0'.; }; @assert t(setr(C, ulocal(f.get-player-stat, %qP, crew object)))={ @trigger me/tr.error=%#, ulocal(layout.crew-object-error, %0, %1, %qP, %#); }; @assert ulocal(f.is-allowed-to-edit-crew, %#, %qP)={ @trigger me/tr.error=%#, You can't edit your crew once it's locked.; }; @assert t(setr(N, ulocal(f.find-cohort, %qC, first(%1, =))))={ @trigger me/tr.error=%#, Could not find a cohort matching '[first(%1, =)]' in [ulocal(f.get-name, %qP, %#)]'s crew.; }; @assert cand(gettimer(%qP, cohort-destroy, %qN), match(rest(%1, =), YES))={ @eval settimer(%qP, cohort-destroy, 600, %qN); @trigger me/tr.message=%#, This will destroy [ulocal(f.get-player-stat, %qP, Crew Name)]'s cohort '%ch%qN%cn'. If you would like to continue%, type %ch+cohort/destroy [ulocal(f.get-name, %qP, %#)]/%qN=YES%cn within the next 10 minutes. It is now [prettytime()].; }; @wipe %qP/_stat.*.[ulocal(f.get-stat-location, %qN)]; @trigger me/tr.add-or-remove-stat=Cohorts, %qN, %qC, %#, 1, Cohort;

@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@
@@ Cohort editing
@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@

&c.+cohort/edit [v(d.cg)]=$+cohort/edit *:@break strmatch(%0, */*); @assert t(setr(C, ulocal(f.get-player-stat, %#, crew object)))={ @trigger me/tr.error=%#, ulocal(layout.crew-object-error, %0, %1, %#, %#); }; @assert ulocal(f.is-allowed-to-edit-crew, %#, %#)={ @trigger me/tr.error=%#, You can't edit your crew once it's locked.; }; @assert t(setr(N, ulocal(f.find-cohort, %qC, first(%0, =))))={ @trigger me/tr.error=%#, Could not find a cohort matching '[first(%0, =)]' in your crew.; }; @set %#=_stat.cohort.editing:%#/%qN; @trigger me/tr.success=%#, You are now editing the %ch[ulocal(f.get-player-stat, %qC, crew name)]%cn cohort '%ch%qN%cn'.; 

&c.+cohort/edit_staff [v(d.cg)]=$+cohort/edit */*: @assert isstaff(%#)={ @trigger me/tr.error=%#, You must be staff to edit a player's cohort.; }; @assert t(setr(P, ulocal(f.find-player, %0, %#)))={ @trigger me/tr.error=%#, Could not find a player named '%0'.; }; @assert t(setr(C, ulocal(f.get-player-stat, %qP, crew object)))={ @trigger me/tr.error=%#, ulocal(layout.crew-object-error, %0, %1, %qP, %#); }; @assert ulocal(f.is-allowed-to-edit-crew, %#, %qP)={ @trigger me/tr.error=%#, You can't edit your crew once it's locked.; }; @assert t(setr(N, ulocal(f.find-cohort, %qC, first(%1, =))))={ @trigger me/tr.error=%#, Could not find a cohort matching '[first(%1, =)]' in [ulocal(f.get-name, %qP, %#)]'s crew.; }; @set %#=_stat.cohort.editing:%qP/%qN; @trigger me/tr.success=%#, You are now editing the %ch[ulocal(f.get-player-stat, %qC, crew name)]%cn cohort '%ch%qN%cn'.;

@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@
@@ Set cohort stats - this turned out to be way more massive than expected...
@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@

&c.+cohort/set [v(d.cg)]=$+cohort/set *=*: @eval strcat(setq(E, xget(%#, _stat.cohort.editing)), setq(P, first(%qE, /)), setq(N, rest(%qE, /))); @assert cand(t(%qP), t(%qN))={ @trigger me/tr.error=%#, You are not currently editing a Cohort. Type %ch+cohort/edit <name>%cn first.; }; @assert t(setr(C, ulocal(f.get-player-stat, %qP, crew object)))={ @trigger me/tr.error=%#, ulocal(layout.crew-object-error, %0, %1, %qP, %#); }; @assert ulocal(f.is-allowed-to-edit-crew, %qC, %#)={ @trigger me/tr.error=%#, You can't edit a crew once it's locked.; }; @assert t(ulocal(f.find-cohort, %qC, %qN))={ @trigger me/tr.error=%#, Could not find a Cohort matching '%qN' in %ch[ulocal(f.get-player-stat, %qC, Crew Name)]%cn. Did it get destroyed or renamed?; }; @assert t(setr(S, ulocal(f.find-cohort-stat-name, %0)))={ @trigger me/tr.error=%#, Could not find a Cohort stat named '%0'. Valid stats are: [ulocal(layout.list, xget(%vD, d.cohort.stats))].; }; @assert not(ulocal(f.is-addable-cohort-stat, %qS))={ @force %#=+cohort/add %qS=%1; }; @assert t(setr(V, ulocal(f.get-cohort-stat-pretty-value, %qS, %1)))={ @trigger me/tr.error=%#, '%1' is not a valid value for %qS. Valid values are [ulocal(layout.list, ulocal(f.list-cohort-stat-pretty-values, %qS))].; }; @assert cor(not(strmatch(%qS, Specialty)), strmatch(ulocal(f.get-cohort-stat, %qC, %qN, Cohort Type), Expert))={ @trigger me/tr.error=%#, Gangs cannot have Specialties. %ch+cohort/set Cohort Type=Expert%cn if you want this cohort to have a Specialty.; }; @assert cor(not(strmatch(%qS, Name)), cand(valid(attrname, setr(W, ulocal(f.get-stat-location-on-player, cohort_type.%1))), lte(strlen(%qW), 60)))={ @trigger me/tr.error=%#, The name '%1' cannot be translated into a valid attribute name%, which means it won't work. Please change the name or open a job with staff requesting a fix.; }; @assert cor(not(strmatch(%qS, Name)), not(t(setr(A, finditem(ulocal(f.get-player-stat, %qC, Cohorts), %1, |)))), not(strmatch(%qA, %1)))={ @trigger me/tr.error=%#, There is already a cohort named %qA.; }; @set %qC=ulocal(f.get-stat-location-on-player, %qS.%qN):%qV; @trigger me/tr.success=%#, You set the %ch[ulocal(f.get-player-stat, %qC, crew name)]%cn cohort %ch%qN%cn's %qS to %ch%qV%cn.; @trigger me/tr.crew-emit=%qC, ulocal(f.get-name, %#) set the crew Cohort %ch%qN%cn's %qS to %ch%qV%cn.; @assert not(strmatch(%qS, Name))={ @set %#=_stat.cohort.editing:%qC/%1; @set %qC=[ulocal(f.get-stat-location-on-player, Cohorts)]:[replace(setr(L, ulocal(f.get-player-stat, %qC, Cohorts)), member(%qL, %qN, |), %1, |, |)]; @dolist lattr(strcat(%qC, /, ulocal(f.get-stat-location-on-player, *.%qN)))={ @mvattr %qC=##, ulocal(f.get-stat-location, strcat(extract(##, 1, 2, .), ., %1)); }; };

@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@
@@ Add Flaws, Edges, and Types to a cohort
@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@

&c.+cohort/add [v(d.cg)]=$+cohort/add *=*: @eval strcat(setq(E, xget(%#, _stat.cohort.editing)), setq(P, first(%qE, /)), setq(N, rest(%qE, /))); @assert cand(t(%qP), t(%qN))={ @trigger me/tr.error=%#, You are not currently editing a Cohort. Type %ch+cohort/edit <name>%cn first.; }; @assert t(setr(C, ulocal(f.get-player-stat, %qP, crew object)))={ @trigger me/tr.error=%#, ulocal(layout.crew-object-error, %0, %1, %qP, %#); }; @assert ulocal(f.is-allowed-to-edit-crew, %qC, %#)={ @trigger me/tr.error=%#, You can't edit a crew once it's locked.; }; @assert t(ulocal(f.find-cohort, %qC, %qN))={ @trigger me/tr.error=%#, Could not find a Cohort matching '%qN' in %ch[ulocal(f.get-player-stat, %qC, Crew Name)]%cn. Did it get destroyed or renamed?; }; @assert t(setr(S, ulocal(f.find-cohort-stat-name, %0)))={ @trigger me/tr.error=%#, Could not find a Cohort stat named '%0'. Valid stats are: [ulocal(layout.list, xget(%vD, d.cohort.stats))].; }; @assert ulocal(f.is-addable-cohort-stat, %qS)={ @force %#=+cohort/set %qS=%1; }; @assert t(setr(V, ulocal(f.get-cohort-stat-pretty-value, %qS, %1, setr(O, ulocal(f.get-cohort-stat, %qC, %qN, cohort_type)))))={ @trigger me/tr.error=%#, '%1' is not a valid value for %qS. Valid values are [ulocal(layout.list, ulocal(f.list-cohort-stat-pretty-values, %qS, %qO))].; }; @assert cor(not(strmatch(%qS, Types)), not(strmatch(%qO, Vehicle)))={ @trigger me/tr.error=%#, Vehicles cannot have additional Types.; };  @eval setq(E, ulocal(f.get-cohort-stat, %qC, %qN, %qS)); @assert not(t(finditem(%qE, %qV, |)))={ @trigger me/tr.error=%#, '%qV' is already one of this Cohort's %qS.; };  @assert lte(inc(words(ulocal(f.get-cohort-stat, %qC, %qN, %qS), |)), 2)={ @trigger me/tr.error=%#, Adding %qV would take you over 2 %qS. Remove one or more existing %qS before adding a new one.; }; @eval setq(T, ulocal(f.count-upgrades, %qC)); @assert cor(not(strmatch(%qS, Types)), ulocal(f.is-allowed-to-break-stat-setting-rules, %#, %qC), lte(add(%qT, 2), 4))={ @trigger me/tr.error=%#, ulocal(layout.upgrade-max, %qT, 0, %qC, %#); }; @set %qC=[ulocal(f.get-stat-location-on-player, %qS.%qN)]:[trim(%qE|%qV, b, |)]; @trigger me/tr.success=%#, You add '%ch[if(cand(strmatch(%qS, Types), strmatch(ulocal(f.get-cohort-stat, %qC, %qN, cohort type), Expert)), mid(%qV, 0, dec(strlen(%qV))), %qV)]%cn' to %ch[ulocal(f.get-player-stat, %qC, crew name)]%cn cohort %ch%qN%cn's %qS.; @trigger me/tr.crew-emit=%qC, ulocal(f.get-name, %#) added '%ch[if(cand(strmatch(%qS, Types), strmatch(ulocal(f.get-cohort-stat, %qC, %qN, cohort type), Expert)), mid(%qV, 0, dec(strlen(%qV))), %qV)]%cn' to the crew's Cohort %ch%qN%cn's %qS.;

@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@
@@ Remove Flaws, Edges, and Types from a cohort
@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@

&c.+cohort/remove [v(d.cg)]=$+cohort/remove *=*: @eval strcat(setq(E, xget(%#, _stat.cohort.editing)), setq(P, first(%qE, /)), setq(N, rest(%qE, /))); @assert cand(t(%qP), t(%qN))={ @trigger me/tr.error=%#, You are not currently editing a Cohort. Type %ch+cohort/edit <name>%cn first.; }; @assert t(setr(C, ulocal(f.get-player-stat, %qP, crew object)))={ @trigger me/tr.error=%#, ulocal(layout.crew-object-error, %0, %1, %qP, %#); }; @assert ulocal(f.is-allowed-to-edit-crew, %qC, %#)={ @trigger me/tr.error=%#, You can't edit a crew once it's locked.; }; @assert t(ulocal(f.find-cohort, %qC, %qN))={ @trigger me/tr.error=%#, Could not find a Cohort matching '%qN' in %ch[ulocal(f.get-player-stat, %qC, Crew Name)]%cn. Did it get destroyed or renamed?; }; @assert t(setr(S, ulocal(f.find-cohort-stat-name, %0)))={ @trigger me/tr.error=%#, Could not find a Cohort stat named '%0'. Valid stats are: [ulocal(layout.list, xget(%vD, d.cohort.stats))].; }; @assert t(setr(V, ulocal(f.get-cohort-stat-pretty-value, %qS, %1, setr(O, ulocal(f.get-cohort-stat, %qC, %qN, cohort_type)))))={ @trigger me/tr.error=%#, '%1' is not a valid value for %qS. Valid values are [ulocal(layout.list, ulocal(f.list-cohort-stat-pretty-values, %qS, %qO))].; }; @assert ulocal(f.is-addable-cohort-stat, %qS)={ @force %#=+cohort/set %qS=%1; }; @eval setq(E, ulocal(f.get-cohort-stat, %qC, %qN, %qS)); @assert t(finditem(%qE, %qV, |))={ @trigger me/tr.error=%#, '%qV' is not one of this Cohort's %qS.; }; @assert gt(words(%qE, |), 1)={ @trigger me/tr.error=%#, Removing %qV would take the cohort down to no %qS. Add new %qS before you remove this one.; };  @set %qC=[ulocal(f.get-stat-location-on-player, %qS.%qN)]:[remove(%qE, %qV, |, |)]; @trigger me/tr.success=%#, You remove '%ch[if(cand(strmatch(%qS, Types), strmatch(ulocal(f.get-cohort-stat, %qC, %qN, cohort type), Expert)), mid(%qV, 0, dec(strlen(%qV))), %qV)]%cn' from %ch[ulocal(f.get-player-stat, %qC, crew name)]%cn cohort %ch%qN%cn's %qS.; @trigger me/tr.crew-emit=%qC, ulocal(f.get-name, %#) removed '%ch[if(cand(strmatch(%qS, Types), strmatch(ulocal(f.get-cohort-stat, %qC, %qN, cohort type), Expert)), mid(%qV, 0, dec(strlen(%qV))), %qV)]%cn' from the crew's Cohort %ch%qN%cn's %qS.;

@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@
@@ Factions
@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@

&layout.faction-log [v(d.cgf)]=strcat(setq(C, ulocal(f.get-player-stat, %0, crew object)), setq(L, ulocal(f.get-last-X-logs, %qC, _faction-, 99)), if(t(%qL), strcat(header(cat(Last 99 faction logs, for, ulocal(f.get-crew-name, %qC)), %1), %r, formattext(iter(%qL, ulocal(layout.log, xget(%qC, itext(0))),, %r), 0, %1), %r, footer(, %1)), cat(alert(Faction logs), No logs found for this crew.)))

&layout.factions [v(d.cgf)]=strcat(setq(C, ulocal(f.get-player-stat, %0, crew object)), header(All Factions, %1), %r, setq(F, ulocal(f.get-player-stat, %qC, Factions)), setq(H, ulocal(f.get-player-stat, %qC, hunting grounds)), setq(W, getremainingwidth(%1, 2)), edit(multicol(fliplist(iter(xget(%vD, d.factions), strcat(divider(ulocal(f.convert-stat-to-title, itext(0)), %qW), |, iter(xget(%vD, itext(0)), cat(_, ulocal(f.get-faction-status, %qC, itext(0)), strcat(itext(0), if(t(member(xget(%vD, ulocal(f.get-stat-location, d.%qH.factions)), itext(0), |)), %ch%cy *%cn))), |, |)),, |), 2, |), * *, 0, |), _, %b), %r, footer(%ch%cy*%cn indicates factions that claim this crew's hunting grounds, %1))

&c.+factions [v(d.cg)]=$+factions:@pemit %#=ulocal(layout.factions, %#, %#);

&c.+factions_player [v(d.cg)]=$+factions *:@assert isstaff(%#)={ @trigger me/tr.error=%#, You must be staff to view a player's factions.; }; @assert t(setr(P, ulocal(f.find-player, %0, %#)))={ @trigger me/tr.error=%#, Could not find a player named '%0'.; }; @assert t(setr(C, ulocal(f.get-player-stat, %qP, crew object)))={ @trigger me/tr.error=%#, ulocal(layout.crew-object-error, %0, %1, %qP, %#); }; @pemit %#=ulocal(layout.subsection, crew-factions, %qC, %#);

&c.+faction/log [v(d.cg)]=$+faction/log:@pemit %#=ulocal(layout.faction-log, %#, %#);

&c.+faction/log_player [v(d.cg)]=$+faction/log *:@assert isstaff(%#)={ @trigger me/tr.error=%#, You must be staff to view a player's factions.; }; @assert t(setr(P, ulocal(f.find-player, %0, %#)))={ @trigger me/tr.error=%#, Could not find a player named '%0'.; }; @assert t(setr(C, ulocal(f.get-player-stat, %qP, crew object)))={ @trigger me/tr.error=%#, ulocal(layout.crew-object-error, %0, %1, %qP, %#); }; @pemit %#=ulocal(layout.faction-log, %qC, %#);

@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@
@@ +faction/set
@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@

&c.+faction/set [v(d.cg)]=$+faction/set *=*:@break strmatch(%0, */*); @trigger me/tr.faction-set=%0, %1, %#, %#;

&c.+faction/set_staff [v(d.cg)]=$+faction/set */*=*:@assert isstaff(%#)={ @trigger me/tr.error=%#, You must be staff to set a crew's factions.; }; @assert t(setr(P, ulocal(f.find-player, %0, %#)))={ @trigger me/tr.error=%#, Could not find a player named '%0'.; }; @if isnum(first(%2))={ @trigger me/tr.faction-set-number=%2, %1, %qP, %#; }, { @trigger me/tr.faction-set=%1, %2, %qP, %#; };

&tr.faction-set-number [v(d.cg)]=@assert t(setr(C, ulocal(f.get-player-stat, %2, crew object)))={ @trigger me/tr.error=%3, ulocal(layout.crew-object-error, %0, %1, %2, %3); }; @assert t(setr(F, finditem(setr(L, switch(%qQ, Hunting, xget(%vD, ulocal(f.get-stat-location, d.%qH.factions)), ulocal(f.get-all-factions))), %1, |)))={ @trigger me/tr.error=%3, '%1' is not a valid Faction. [if(lte(words(%qL, |), 10), cat(Available factions are, ulocal(layout.list, %qL).), You can view the list of factions with +factions.)]; }; @eval setq(V, if(isint(first(%0)), first(%0), 0)); @eval strcat(setq(R, if(isint(first(%0)), rest(%0), %0)), setq(R, squish(trim(switch(%qR, for *, rest(%qR), %qR))))); @assert t(%qR)={ @trigger me/tr.error=%3, Can't figure out what your reason for changing this faction relationship was.; }; @assert cand(isint(%qV), gte(%qV, -3), lte(%qV, 3))={ @trigger me/tr.error=%3, %qV must be a number between -3 and +3.; }; @eval setq(E, ulocal(f.get-player-stat, %qC, Factions)); @eval if(ulocal(f.has-list-stat, %qC, Factions, %qF), strcat(setq(I, member(iter(%qE, rest(itext(0)), |, |), %qF, |)), setq(E, replace(%qE, %qI, strip(ulocal(f.get-faction-status-color, %qV)) %qF, |, |))), setq(E, trim(strcat(%qE, |, strip(ulocal(f.get-faction-status-color, %qV)) %qF), b, |))); @trigger me/tr.set-final-stat=Factions, %qE, %qC, %3,, cat(You set, ulocal(f.get-crew-name, %qC)'s faction relationship with %ch%qF%cn to, ulocal(f.get-faction-status-color, %qV), because '%qR'.), cat(ulocal(f.get-name, %3), sets your crew's faction relationship with %ch%qF%cn to, ulocal(f.get-faction-status-color, %qV), because '%qR'.); @trigger me/tr.log=%qC, _faction-, %3, cat(Set relationship with %ch%qF%cn to, ulocal(f.get-faction-status-color, %qV), because '%qR'.);

&tr.faction-set [v(d.cg)]=@assert t(setr(C, ulocal(f.get-player-stat, %2, crew object)))={ @trigger me/tr.error=%3, ulocal(layout.crew-object-error, %0, %1, %2, %3); }; @assert ulocal(f.is-allowed-to-edit-crew, %qC, %3)={ @trigger me/tr.error=%3, You can't edit a crew once it's locked.; }; @assert t(setr(Q, finditem(xget(%vD, d.faction.questions), %0, |)))={ @trigger me/tr.error=%3, '%0' is not a valid Faction Question. Faction Questions are: [ulocal(layout.list, xget(%vD, d.faction.questions))].; }; @assert cor(not(strmatch(%qQ, Hunting)), t(setr(H, ulocal(f.get-player-stat, %qC, hunting grounds))))={ @trigger me/tr.error=%3, You can't choose the faction that claims this crew's Hunting Grounds until the crew's Hunting Grounds are set.; }; @assert t(setr(F, finditem(setr(L, switch(%qQ, Hunting, xget(%vD, ulocal(f.get-stat-location, d.%qH.factions)), ulocal(f.get-all-factions))), %1, |)))={ @trigger me/tr.error=%3, '%1' is not a valid Faction. [if(lte(words(%qL, |), 10), cat(Available factions are, ulocal(layout.list, %qL).), You can view the list of factions with +factions.)]; }; @assert case(%qQ, Helped, not(strmatch(%qF, first(ulocal(f.get-player-stat, %qC, faction.harmed), |))), Harmed, not(strmatch(%qF, first(ulocal(f.get-player-stat, %qC, faction.helped), |))), 1)={ @trigger me/tr.error=%3, The faction who helped this crew cannot be the same faction that harmed the crew.; }; @assert case(%qQ, Friendly, not(strmatch(%qF, first(ulocal(f.get-player-stat, %qC, faction.unfriendly), |))), Unfriendly, not(strmatch(%qF, first(ulocal(f.get-player-stat, %qC, faction.friendly), |))), 1)={ @trigger me/tr.error=%3, The faction who is friendly to this crew cannot be the same faction that is unfriendly to them.; }; @eval setq(T, rest(ulocal(f.get-player-stat-or-default, %qC, faction.%qQ, |0), |)); @set %qC=[ulocal(f.get-stat-location-on-player, faction.%qQ)]:%qF|%qT; @wipe %qC/[ulocal(f.get-stat-location-on-player, Factions)]; @trigger me/tr.recalculate-factions=%qC; @trigger me/tr.success=%3, You set %ch[ulocal(f.get-player-stat, %qC, Crew Name)]%cn's %qQ faction to %ch%qF%cn. [if(t(member(Friendly|Unfriendly, %qQ, |)), if(t(%qT), This crew has an intensified relationship with this faction, This crew has a normal relationship with this faction), This crew has paid them %qT coin)] for a total status of [ulocal(f.get-faction-status, %qC, %qF)].; @trigger me/tr.crew-emit=%qC, ulocal(f.get-name, %3) sets the crew's %qQ faction to %ch%qF%cn. [if(t(member(Friendly|Unfriendly, %qQ, |)), if(t(%qT), This crew has an intensified relationship with this faction, This crew has a normal relationship with this faction), This crew has paid them %qT coin)] for a total status of [ulocal(f.get-faction-status, %qC, %qF)].;

&tr.recalculate-factions [v(d.cg)]=@eval setr(E, iter(xget(%vD, d.faction.questions), first(ulocal(f.get-player-stat, %0, strcat(faction., itext(0))), |), |, |)); @set %0=[ulocal(f.get-stat-location-on-player, Factions)]:[setunion(setr(L, stripansi(iter(%qE, cat(ulocal(f.get-faction-status, %0, itext(0)), itext(0)), |, |))), %qL, |)];

@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@
@@ +faction/pay
@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@

&c.+faction/pay [v(d.cg)]=$+faction/pay *=*:@break strmatch(%0, */*); @trigger me/tr.faction-pay=%0, %1, %#, %#;

&c.+faction/pay_staff [v(d.cg)]=$+faction/pay */*=*:@assert isstaff(%#)={ @trigger me/tr.error=%#, You must be staff to edit a crew's factions.; }; @assert t(setr(P, ulocal(f.find-player, %0, %#)))={ @trigger me/tr.error=%#, Could not find a player named '%0'.; }; @trigger me/tr.faction-pay=%0, %1, %qP, %#;

&c.+faction/boost [v(d.cg)]=$+faction/boost:@assert lte(rest(ulocal(f.get-player-stat, ulocal(f.get-player-stat, %#, crew object), strcat(faction., Friendly)), |), 0)={ @trigger me/tr.error=%#, You have already boosted your crew's relations with their Friendly and Unfriendly factions.; }; @trigger me/tr.faction-pay=Friendly, 1, %#, %#, You have increased this crew's reputation with their Friendly faction; @trigger me/tr.faction-pay=Unfriendly, -1, %#, %#, You have decreased this crew's reputation with their Unfriendly faction;

&c.+faction/boost_staff [v(d.cg)]=$+faction/boost *:@assert isstaff(%#)={ @trigger me/tr.error=%#, You must be staff to edit a crew's factions.; }; @assert t(setr(P, ulocal(f.find-player, %0, %#)))={ @trigger me/tr.error=%#, Could not find a player named '%0'.; }; @assert lte(rest(ulocal(f.get-player-stat, ulocal(f.get-player-stat, %qP, crew object), strcat(faction., Friendly)), |), 0)={ @trigger me/tr.error=%#, You have already boosted this crew's relations with their Friendly and Unfriendly factions.; }; @trigger me/tr.faction-pay=Friendly, 1, %qP, %#, You have increased this crew's reputation with their Friendly faction; @trigger me/tr.faction-pay=Unfriendly, -1, %qP, %#, You have decreased this crew's reputation with their Unfriendly faction;

&c.+faction/unboost [v(d.cg)]=$+faction/unboost:@assert gt(rest(ulocal(f.get-player-stat, ulocal(f.get-player-stat, %#, crew object), strcat(faction., Friendly)), |), 0)={ @trigger me/tr.error=%#, Your crew's relations with their Friendly and Unfriendly factions are already unboosted.; }; @trigger me/tr.faction-pay=Friendly, 0, %#, %#, You have normalized this crew's reputation with their Friendly faction; @trigger me/tr.faction-pay=Unfriendly, 0, %#, %#, You have normalized this crew's reputation with their Unfriendly faction;

&c.+faction/unboost_staff [v(d.cg)]=$+faction/unboost *:@assert isstaff(%#)={ @trigger me/tr.error=%#, You must be staff to edit a crew's factions.; }; @assert t(setr(P, ulocal(f.find-player, %0, %#)))={ @trigger me/tr.error=%#, Could not find a player named '%0'.; }; @assert gt(rest(ulocal(f.get-player-stat, ulocal(f.get-player-stat, %qP, crew object), strcat(faction., Friendly)), |), 0)={ @trigger me/tr.error=%#, This crew's relations with their Friendly and Unfriendly factions are already unboosted.; }; @trigger me/tr.faction-pay=Friendly, 0, %qP, %#, You have normalized this crew's reputation with their Friendly faction; @trigger me/tr.faction-pay=Unfriendly, 0, %qP, %#, You have normalized this crew's reputation with their Unfriendly faction;

&tr.faction-pay [v(d.cg)]=@assert t(setr(C, ulocal(f.get-player-stat, %2, crew object)))={ @trigger me/tr.error=%3, ulocal(layout.crew-object-error, %0, %1, %2, %3); }; @assert ulocal(f.is-allowed-to-edit-crew, %qC, %3)={ @trigger me/tr.error=%3, You can't edit a crew once it's locked.; }; @assert t(setr(Q, finditem(setr(L, setdiff(xget(%vD, d.faction.questions), if(not(t(%4)), Friendly|Unfriendly), |)), %0, |)))={ @trigger me/tr.error=%3, '%0' is not a valid Faction Question that can be paid. Payable Faction Questions are: [ulocal(layout.list, %qL)].; }; @assert cor(not(strmatch(%qQ, Hunting)), t(setr(H, ulocal(f.get-player-stat, %qC, hunting grounds))))={ @trigger me/tr.error=%3, This crew can't pay the faction that claims their Hunting Grounds until they choose their Hunting Grounds.; }; @eval setq(T, ulocal(f.get-player-stat-or-default, %qC, faction.%qQ, |0)); @eval setq(F, first(%qT, |)); @assert t(%qF)={ @trigger me/tr.error=%3, The crew needs to set a %qQ faction before they can pay them.; }; @assert cand(isint(%1), cor(gte(%1, 0), strmatch(%qQ, Unfriendly)), lte(%1, switch(%qQ, Hunting, 2, 1)))={ @trigger me/tr.error=%3, '%1' is not a valid amount to pay. This crew can pay [ulocal(layout.list, lnum(switch(%qQ, Hunting, 3, 2),, |), or)] Coin.; }; @assert lte(add(setr(X, ulocal(f.get-total-faction-coin, %qC, %qQ)), %1), 2)={ @trigger me/tr.error=%3, Your crew has 2 coin total. %qX of it has already been spent.; }; @set %qC=[ulocal(f.get-stat-location-on-player, faction.%qQ)]:[replace(%qT, 2, %1, |, |)]; @wipe %qC/[ulocal(f.get-stat-location-on-player, Factions)]; @trigger me/tr.recalculate-factions=%qC; @trigger me/tr.success=%3, if(t(%4), %4, You have paid your crew's %qQ faction%, %ch%qF%cn%, %1 coin) for a total status of [ulocal(f.get-faction-status, %qC, %qF)].; @trigger me/tr.crew-emit=%qC, if(t(%4), edit(%4, You have, ulocal(f.get-name, %3) has), ulocal(f.get-name, %3) has paid the crew's %qQ faction%, %ch%qF%cn%, %1 coin) for a total status of [ulocal(f.get-faction-status, %qC, %qF)].;

@@ TODO: Make it so that +faction/pay Unfriendly|Friendly just lower/raise intensity rather than costing coin or being rejected.

@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@
@@ +claim/award
@@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ @@

&f.find-claim [v(d.cgf)]=if(t(member(A1 A2 A3 A4 A5 B1 B2 B4 B5 C1 C2 C3 C4 C5, ucstr(%1))), ulocal(f.get-map-key, %0, %1)|%1, if(t(setr(F, finditem(setr(L, xget(%vD, strcat(d.map., ulocal(f.get-player-stat, %0, crew type)))), %1, |))), strcat(%qF, |, switch(member(%qL, %qF, |), <6, A#$, 6, B1, 7, B2, 8, B4, 9, B5, strcat(C, inc(div(#$, 5))))), %1|0))

&c.+claim/award [v(d.cg)]=$+claim/award *=*:@assert isstaff(%#)={ @trigger me/tr.error=%#, You must be staff to change a player's stats.; }; @assert t(setr(P, ulocal(f.find-player, %0, %#)))={ @trigger me/tr.error=%#, Could not find a player named '%0'.; }; @eval setq(N, ulocal(f.get-name, %qP, %#)); @assert t(setr(C, ulocal(f.get-player-stat, %qP, crew object)))={ @trigger me/tr.error=%#, %qN is not in a crew and can't have a claim set up.; }; @eval strcat(setq(M, ulocal(f.find-claim, %qC, %1)), setq(A, rest(%qM, |)), setq(M, first(%qM, |))); @assert t(%qM)={ @trigger me/tr.error=%#, '%1' couldn't be resolved into a claim.; }; @assert not(strmatch(%qM, B3))={ @trigger me/tr.error=%#, 'B3' is not a valid claim.; }; @assert t(%qM)={ @trigger me/tr.error=%#, Couldn't figure out what kind of claim to grant. You entered '%1'.; }; @assert not(t(ulocal(f.get-player-stat, %qC, Map %qA)))={ @trigger me/tr.error=%#, %qN's crew already has the claim %qA%, '%qM'.; }; @if t(%qA)={ @trigger me/tr.set-final-stat=Map %qA, %qM, %qC, %#,, cat(You award, ansi(h, ulocal(layout.whose-stat, Claims, %qM, %qC, %#)), claim '%ch%qM%cn'.), cat(ulocal(f.get-name, %#), awarded your crew the claim '%ch%qM%cn'.); }, { @trigger me/tr.add-or-remove-stat=Claims, %qM, %qC, %#; };
