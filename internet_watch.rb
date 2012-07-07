require 'active_support/core_ext/numeric'
require 'colorize'
require 'mail'
require 'net/ping'
include Net

net = Net::Ping::External.new("google.com")

UP = true
DOWN = false

#
#   Mail Settings
#
Mail.defaults do
  delivery_method :smtp, { 
    :address => 'smtp.gmail.com',
    :port => '587',
    :user_name => ENV['GMAIL_USER'], # exec `export GMAIL_USER="xxxxx@gmail.com" to set ENV
    :password => ENV['GMAIL_PASSWORD'], # ditto ^
    :authentication => :plain,
    :enable_starttls_auto => true
  }
end

@mail = Mail.new do
  # to 'vidur.murali@gmail.com'
  to 'trigger@ifttt.com'
  from 'vidur.murali@gmail.com'
  subject 'Internet is #up'
  body '#up'
end

# Notifies through growl and colorized terminal output
#   Emails ifttt with #up to trigger text message
def notify(internet_up)
  time = Time.now
  if internet_up
    %x( growlnotify -m "The internet is up!")
    puts "It's back!".blue
    puts "Internet is UP".green + " @ #{time.strftime("%I:%M:%S %p")}"
    puts "Text sent!".blue if @mail.deliver
  else
    %x( growlnotify -m "Internet is DOWN" )
    puts "Internet is DOWN".red + " @ #{time.strftime("%I:%M:%S %p")}"
  end
end


#
#   Ping Script
#

# init internet
notify(internet = (net.ping? ? UP : DOWN) )
last_ping = Time.now
down_for = 0

while true
  now = Time.now
  if now - last_ping >= 1.seconds # ping every second
    if net.ping?
      if internet == DOWN and down_for >= 5.seconds
        notify(internet = UP)
      end
      down_for = 0 # reset down time
    else
      if internet == UP
        down_for += 1
        notify(internet = DOWN) if down_for >= 5.seconds
      end
    end # end if net.ping?
    last_ping = now
  end
end # end while