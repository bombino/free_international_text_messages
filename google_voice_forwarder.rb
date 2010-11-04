#!/usr/bin/env ruby

config = {
  :google_account_email => "XXXXXXXXXX@gmail.com",
  :google_account_password => "YYYYYYYYY",
  :gosim_username => "ZZZZ",
  :gosim_password => "WWWW",
  :gosim_number => "372xxxxxxxxxx"
}

require 'rubygems'
require 'cgi'
require 'gvoice-ruby'

google_config = {
  :google_account_email => config[:google_account_email],
  :google_account_password => config[:google_account_password],
  :google_auth_url => "https://www.google.com/accounts/ServiceLoginAuth",
  :google_voice_feed_url => "https://www.google.com/voice/inbox/recent",
  :logfile => "/tmp/google_voice_forwarder.txt"
}

data = []

voicebox = GvoiceRuby::Client.new(google_config)
voicebox.check

if voicebox.any_unread?
  voicebox.smss.each do |t|
    if t.labels.include?('unread')
      data << "#{t.from}: #{t.text}"
      voicebox.mark_as_read({:id => t.id})
      voicebox.add_note({:id => t.id, :note => "Forwarded to International Phone at #{Time.now}."})
    end
  end
  voicebox.voicemails.each do |v|
    if v.labels.include?('unread') and (!(v.transcript =~ /in progress/))
      data << "#{v.from} VM: #{v.transcript}" unless v.transcript =~ /Press 2/
      voicebox.mark_as_read({:id => v.id})
    end
  end
end

if data.size > 0
  string = data.join("; ")
  LENGTH = 130
  `curl -c /tmp/gosimcookie.txt https://www.mygosim.com/`
  `curl -b /tmp/gosimcookie.txt -c /tmp/gosimcookie.txt -d "username=#{config[:gosim_username]}&password=#{config[:gosim_password]}&Sign+in=Sign+in&HTTP_REFERER=https%3A%2F%2Fwww.mygosim.com%2Fsend_text_message.html&force_referer=" https://www.mygosim.com/do/com.login.php`
  1.upto((string.length.to_f / LENGTH.to_f).ceil) do |i|
    d = string[((i-1)*LENGTH)..(i*LENGTH)]
    puts d
    `curl -b /tmp/gosimcookie.txt -c /tmp/gosimcookie.txt -d "bnum_select=#{config[:gosim_number]}&prefix=#{config[:gosim_number][0..2]}&message=#{CGI::escape(d)}" https://www.mygosim.com/do/api.send_text_message.php`
  end
end
