class Notify
	@firebase

	def initialize(firebase)
		@firebase = firebase
	end

	def global(time = nil)
		if(time)
			@firebase.set("notifications/next", time)
		else
			Time.parse(@firebase.get("notifications/next").body)
		end
	end

	def stop(chat_id)
		@firebase.delete("notifications/users/" + chat_id)
	end

	def get(chat_id)
		n = @firebase.get("notifications/users/" + chat_id)
		return n ? n.body : nil
	end

	def next_time(chat_id, tick)
		t = Time.now
		t = Time.new(t.year, t.month, t.day, t.hour) + (60*60*tick)
		@firebase.set("notifications/users/" + chat_id + "/next", t)
	end

	def set_tick(chat_id, tick)
		@firebase.set("notifications/users/" + chat_id + "/tick", tick)
		next_time(chat_id, tick)
	end

	def sleep_hours(chat_id, data = nil)
		if(data)
			@firebase.set("notifications/users/" + chat_id + "/sleep", data)
		else
			hours = @firebase.get("notifications/users/" + chat_id + "/sleep").body
			return hours ? { start: hours['start'], end: hours['end'] } : nil
		end
	end

	def all()
		notified = @firebase.get("notifications/users").body.to_a
		!notified.empty? ? notified.map { |n| { 
			id: n[0],
			next: Time.parse(n[1]['next']),
			tick: n[1]['tick'].to_i,
			sleep: n[1]['sleep'] ? {
				start: n[1]['sleep']['start'].to_i,
				end: n[1]['sleep']['end'].to_i
			} : nil
		}
		} : nil
	end
end