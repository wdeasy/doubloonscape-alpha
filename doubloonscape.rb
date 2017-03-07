require 'discordrb'
require 'active_support/time'
require 'date'
require 'time'
require 'csv'
require 'thread'
require 'json'

$id = 'bot id here'
$token = 'bot token here'
$owner = 'bot owner id here'
$role = 'role id here'
$server = 'server id here'
$channel = 'channel id here'
$seconds = 60
$base = 60
$multiplier = 1.1
$offline = 5
$immune = 60
$bonus = 0.1
$ships = ['🚢',':ship:']
$last_captain = (Time.now() - 1.minute)
$captain = nil

bot = Discordrb::Commands::CommandBot.new token: $token, client_id: $id, prefix: '!'

puts "This bot's invite URL is #{bot.invite_url}."
puts 'Click on it to invite it to your server.'

#id, name, unit, value, achieved

class Achievement
  @@achieves=0
  def initialize(id,desc,unit,value,achieved)
    @@achieves+=1
    @id=id
    @desc=desc
    @unit=unit
    @value=value
    @achieved=achieved
  end

  def id
    return @id
  end

  def desc
    return @desc
  end

  def unit
    return @unit
  end

  def value
    return @value
  end

  def achieved
    return @achieved
  end

  def achieves
    return @@achieves
  end

  def set_true
    @achieved = true
  end

  def set_false
    @achieved = false
  end
end

$achievements = []
$achievements.push(Achievement.new(0,"Take the Captain.",:count,1,false))
$achievements.push(Achievement.new(1,"Take the Captain 5 Times.",:count,5,false))
$achievements.push(Achievement.new(2,"Take the Captain 10 Times.",:count,10,false))
$achievements.push(Achievement.new(3,"Take the Captain 25 Times.",:count,25,false))
$achievements.push(Achievement.new(4,"Take the Captain 50 Times.",:count,50,false))
$achievements.push(Achievement.new(5,"Take the Captain 100 Times.",:count,100,false))
$achievements.push(Achievement.new(6,"Hold the Captain for 1 Hour.",:current,60,false))
$achievements.push(Achievement.new(7,"Hold the Captain for 3 Hours.",:current,60*3,false))
$achievements.push(Achievement.new(8,"Hold the Captain for 6 Hours.",:current,60*6,false))
$achievements.push(Achievement.new(9,"Hold the Captain for 12 Hours.",:current,60*12,false))
$achievements.push(Achievement.new(10,"Hold the Captain for 24 Hours.",:current,60*24,false))
$achievements.push(Achievement.new(11,"Have Over 1 Hour of Total Captain Time.",:total,60,false))
$achievements.push(Achievement.new(12,"Have Over 1 Day of Total Captain Time.",:total,60*24,false))
$achievements.push(Achievement.new(13,"Have Over 1 Week of Total Captain Time.",:total,60*24*7,false))
$achievements.push(Achievement.new(14,"Have Over 1 Month of Total Captain Time.",:total,60*24*31,false))
$achievements.push(Achievement.new(15,"Have Over 1 Year of Total Captain Time.",:total,60*24*365,false))

def loadAchievements(captain, bot)
  $achievements.each do |achieve|
    achieve.set_false
  end

  achievements = $achievements
  if captain[:achieves].empty?
    captain[:achieves] = []
  else
    captain[:achieves] = JSON.parse(captain[:achieves])
  end

  achievements.each do |achieve|
    if captain[:achieves].include? achieve.id
      achieve.set_true
    end
  end

  achievements = achievementCheck(captain, achievements, bot)
  return achievements
end

def achievementCheck(captain, achievements, bot)
  achievements.each do |achieve|
    if captain[achieve.unit] >= achieve.value && achieve.achieved == false
      achieve.set_true
      bot.send_message($channel,"```Achievement Unlocked! #{achieve.desc}```")
    end
  end

  if captain[:current] == captain[:record]
    unless captain[:record] == 0
      bot.send_message($channel, "```#{captain[:name]} has broken his previous record of #{captain[:record]} minutes spent as Captain!```") 
    end
  end

  return achievements
end

def saveAchievements(captain, achievements)
  achievements.each do |achieve|
    if achieve.achieved == true
      unless captain[:achieves].include? achieve.id
        captain[:achieves].push(achieve.id)
      end
    end
  end

  return captain
end

def updateTopic(captain, bot)
  xpNeeded = (($base * ($multiplier ** (captain[:level] - 1))).ceil - captain[:xp]).to_i
  #set channel topic
  begin
    bot.channel($channel).topic = "Level: #{captain[:level]}   Gold: #{captain[:gold]}  Time as Captain: #{captain[:current]} minutes.  Next Level: #{xpNeeded} minutes."
  rescue Exception => msg
    puts "error attempting to set new channel topic"
    puts msg
  end
end

def getName(user)
  nickname = ''
  if user.nickname == nil
    nickname = user.username
  else
    nickname = user.nickname
  end

  if $ships.any? { |ship| nickname.include?(ship) }
    $ships.each do |s|
      nickname.sub! s, ''
    end
  end
  return nickname.strip
end

def firstWinOfDay(captain, bot)
  if captain[:start].empty? || !Date.parse(captain[:start]).today?
    bonus = (($base * ($multiplier ** (captain[:level] - 1))).ceil * $bonus).floor.to_i
    captain[:xp] += bonus
    bot.send_message($channel,"```First Captain of the Day Bonus!```")
  end
  return captain
end

def loadCaptain(event)
  path = "captains/#{event.author.id}.csv"
  name = getName(event.author)
  unless File.file?(path)
    CSV.open(path, "wb") do |csv|
      csv << ["id","name","level","xp","gold","count","start","current","total","record","achieves","created"]
      csv << ["#{event.author.id}","#{name}","1","0","0","0","","0","0","0","","#{Time.now}"] 
    end
  end
  stats = CSV.read(path, :headers=>true)  
  captain = {
    :id => stats[0]["id"],
    :name => getName(event.author),
    :level => stats[0]["level"].to_i,
    :xp => stats[0]["xp"].to_i,
    :gold => stats[0]["gold"].to_i,
    :count => stats[0]["count"].to_i,
    :start => stats[0]["start"],
    :current => 0,    
    :total => stats[0]["total"].to_i,
    :record => stats[0]["record"].to_i,
    :achieves => stats[0]["achieves"],
    :created => stats[0]["created"]}
end

def saveCaptain(captain, achievements)
  captain = saveAchievements(captain, achievements)
  if captain[:record] <= captain[:current]
    captain[:record] = captain[:current]
  end
  path = "captains/#{captain[:id]}.csv"
  CSV.open(path, "wb") do |csv|
    csv << ["id","name","level","xp","gold","count","start","current","total","record","achieves","created"]
    csv << ["#{captain[:id]}",
            "#{captain[:name]}",
            "#{captain[:level]}",
            "#{captain[:xp]}",
            "#{captain[:gold]}",
            "#{captain[:count]}",
            "#{captain[:start]}",
            "#{captain[:current]}",
            "#{captain[:total]}",
            "#{captain[:record]}",
            "#{captain[:achieves]}",
            "#{captain[:created]}"]
  end
end

def levelCheck(captain, bot)
  xpNeeded = ($base * ($multiplier ** (captain[:level] - 1))).ceil
  if captain[:xp] >= xpNeeded
    captain[:level] += 1
    captain[:xp] = (captain[:xp] - xpNeeded).floor
    xpNeeded = $base * ($multiplier ** (captain[:level] - 1)).ceil
    bot.send_message($channel, "```#{captain[:name]} has hit level #{captain[:level]}!```")
    updateTopic(captain, bot)
  end
  return captain
end

def theCaptainNow(event, captainRole, bot)
  captain = loadCaptain(event)
  captain = firstWinOfDay(captain, bot)
  captain[:start] = Time.now  
  captain[:count] += 1
  achievements = loadAchievements(captain, bot)
  updateTopic(captain, bot)
  last_tick = Time.now
  while captain[:id].to_i == $captain.to_i
    captain = levelCheck(captain, bot)
    sleep 0.1
    if Time.now - last_tick >= $seconds
      last_tick += $seconds
      if bot.user(captain[:id]).status == :offline
        bot.channel($channel).topic = "```#{captain[:name]} has abandoned ship!```"
      else
        captain[:xp] += 1
        captain[:gold] += 1
        captain[:current] += 1
        captain[:total] += 1
        achievements = achievementCheck(captain, achievements, bot)
        updateTopic(captain, bot)
        saveCaptain(captain, achievements)        
      end
    end
  end  
end

bot.message(contains: /\b[Ii]'?[Mm] [Tt][Hh][Ee] [Cc][Aa][Pp][Tt][Aa][Ii][Nn] [Nn][Oo][Ww].?/) do |event|
  if event.server != nil && event.channel == $channel
    captainRole = event.server.roles.find { |r| r.id == $role}
    roleFound = false
    if event.author.id == $captain
      event.author.roles.each do |role|
        if role.id == captainRole.id 
          roleFound = true
        end
      end
    end

    if event.author.id != $captain || roleFound == false
      if Time.now < ($last_captain + $immune.seconds)
        bot.send_message($channel,"The captain is immune for #{(($last_captain + $immune.seconds) - Time.now).ceil} more seconds.")
      else
                
        #assign role to new captain
        begin
          event.user.add_role captainRole
          $captain = event.author.id
          $last_captain = Time.now()
        rescue Exception => msg
          puts "error attempting to assign captain to #{event.author.username}"
          puts msg
        end

        if event.author.id == $captain
          #update the nickname of the new captain
          
          nickname = getName(event.author)
          begin
            event.author.nickname = "#{nickname} #{$ships[0]}"   
          rescue Exception => msg
            puts "error attempting to set captain nickname to #{event.author.username}"
            puts msg
          end      

          #iterate through other channel users
          event.server.users.each do |user|
            unless user.id == event.author.id

              #remove captain role from previous captain
              user.roles.each do |role|
                if role.id == captainRole.id 
                  begin
                    user.remove_role(captainRole)
                  rescue Exception => msg
                    puts "error attempting to remove captain role from #{user.username}"
                    puts msg
                  end  
                end
              end

              #remove ships from previous captain username
              if user.nickname == nil
                nickname = user.username
              else
                nickname = user.nickname
              end

              if $ships.any? { |ship| nickname.include?(ship) }
                $ships.each do |s|
                  nickname.sub! s, ''
                end
                begin
                  user.nickname = nickname.strip
                rescue Exception => msg
                  puts "error attempting to remove captain nickname from #{user.username}"
                  puts msg
                end 
              end
            end
          end  

          #start the game
          game = Thread.new { theCaptainNow(event, captainRole, bot) }
          game.join     
        end
      end
    end
  end
end

bot.command(:exit, help_available: false) do |event|
  break unless event.user.id == $owner
  bot.send_message(event.channel.id, 'The ship is goin down!')

  $captain = nil

  sleep 5 #wait for game to save
  exit
end

bot.command(:setup, help_available: false) do |event|
  role = event.server.roles.find { |r| r.name.downcase.include? 'captain' }

  output = "server id: #{event.server.id}\n"
  output += "channel id: #{event.channel.id}\n"
  output += "role id: #{role.id} (#{role.name})\n"
  output += "server owner id: #{event.server.owner.id}\n"
  output += "your id: #{event.author.id}\n"
  
  event.respond output
end

bot.command(:stats, help_available: false) do |event|
  captain = loadCaptain(event)

  unless captain[:count] == 0
    output = "**#{captain[:name]}**\n"
    output += "`Level:                      #{captain[:level]}`\n"
    output += "`Gold:                       #{captain[:gold]}`\n"
    output += "`Captains Taken:             #{captain[:count]}`\n"
    output += "`Longest Time as Captain:    #{captain[:record]}`\n"
    output += "`Total Minutes as Captain:   #{captain[:total]}`\n"
    unless captain[:achieves].empty?
      captain[:achieves] = JSON.parse(captain[:achieves])
      output += "\n**Achievements**\n"
      captain[:achieves].each do |achieve|
         output += "`#{$achievements[achieve].desc}`\n"
      end
    end 
    event.respond output
  end
end

bot.run