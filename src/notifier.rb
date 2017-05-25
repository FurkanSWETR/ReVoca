require 'aws-sdk'
require 'i18n'

require_relative 'fb'

HOUR = 3600
HOURS_IN_DAY = 24

class Notifier
	@fb
	@thread

	def start(bot)
		firebase_url = ENV.fetch('FIREBASE_URL')
		@fb = FB.new(firebase_url)

		@thread = Thread.new{				
			loop do
				now = Time.now
				users = @fb.notify.all
				users.each { |u| notify(bot, u) }

				@fb.notify.global(Time.new(now.year, now.month, now.day, now.hour) + HOUR)

				sleep(Time.new(now.year, now.month, now.day, now.hour) + HOUR - Time.now + 1)
			end
		}
	end

	def notify(bot, user)
		next_time = user[:next]
		if(next_time < Time.now)
			chat_id = user[:id]
			rescheduled = reschedule(chat_id, user[:sleep]) if (user[:sleep])
			return if rescheduled
			@fb.notify.next_time(chat_id, user[:tick])
			response = form_response(chat_id)
			bot.api.send_message(chat_id: chat_id, text: response) if response
		end
	end

	def reschedule(chat_id, sleep_hours)
		hour = Time.now.hour
		if ((sleep_hours[:start] <= sleep_hours[:end]) && (hour >= sleep_hours[:start]) && (hour < sleep_hours[:end]))
			@fb.notify.next_time(chat_id, sleep_hours[:end] - hour)
			return true
		elsif (sleep_hours[:start] >= sleep_hours[:end])
			if (hour < sleep_hours[:end])
				@fb.notify.next_time(chat_id, sleep_hours[:end] - hour)
				return true
			elsif (hour >= sleep_hours[:start])
				@fb.notify.next_time(chat_id, (HOURS_IN_DAY + sleep_hours[:end]) - hour)
				return true
			end
		else
			return false
		end
	end

	def form_response(chat_id)
		voc = @fb.vocs.get(chat_id, @fb.vocs.active(chat_id))
		word = @fb.vocs.words.random(chat_id, voc[:id])
		if (word)
			locale = @fb.locale(chat_id)
			text = I18n.t('languages.flags.' + voc[:llang], :locale => locale) + I18n.t('languages.names.' + voc[:llang], :locale => locale) + ": " + word[:word] + "\n"
			text += I18n.t('languages.flags.' + voc[:klang], :locale => locale) + I18n.t('languages.names.' + voc[:klang], :locale => locale) + ":\n"
			text += word[:translation].map.with_index {|x, i| (i+1).to_s + ") " + x }.join("\n")	
			return text
		else
			return nil
		end
	end

end

