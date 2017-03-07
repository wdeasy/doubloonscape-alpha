
DoubloonScape
===================
DoubloonScape is a game played in our [Discord][1] server based on the Captain Phillips meme.  
Saying "I'm the Captain now." in the channel assigns you the Captain role.  
While you are the Captain, you gain xp and gold.  

----------

Ruby
-------------
This bot requires atleast Ruby 2.3.0 and the following gems:
>discordrb
> activesupport
> date
> time
> csv
> thread
> json

Commands
-------------
I'm the Captain now - Assigns your user the captain role. This role can only be assigned once a minute.

!stats - Prints out your stats.

!setup - Outputs useful IDs to help with setting up the bot.

!exit - Can only be run by the bot owner, shuts down the bot. 


Roles
-------------
You will need to make a Bot Role, and a Captain Role. 

The Bot Role needs:
> Manage Roles
> Manage Channels
> Change Nickname
> Manage Nicknames
> Read Messages
> Send Messages

The Captain role needs:
> Display role members separately from online members
> Allow anyone to @mention this role
> **ALL OTHER PERMISSIONS UNCHECKED**

Assign the Bot Role to your bot user. The roles can be named whatever you want, although the Captain Role needs to have captain in the name in order for !setup to find it. After the Role ID is in the doubloonscape.rb file, it can be changed to whatever you like.

The Role Hierarchy needs to be something like this:
> Admins
> Bot Role
> Captain Role
> @everyone 

All roles above the Captain Role need to have "Display role members separately from online members" unchecked or else they will not be displayed correctly if they declare themselves the Captain.

Setup
-------------
You'll need an ID and Token from the [Discord Developer Page][2].
You get the ID after creating an app, and the Token after converting the App to a Bot User. Adding those two values to doubloonscape.rb should be enough to get the bot started. 

Once the bot is started, get the bot's invite URL from the console and add it to your server. With the bot in your server, typing !setup should give you the rest of the IDs that need to be added to doubloonscape.rb.

----------

With the gems installed, IDs in the file, roles created and assigned, you should be able to start the bot and take the Captain!

  [1]: http://discordapp.com
  [2]: https://discordapp.com/developers
