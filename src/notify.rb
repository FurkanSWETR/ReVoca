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

	def set(chat_id, data)
		@firebase.set("notifications/users/" + chat_id, data)
	end

	def all()
		notified = @firebase.get("notifications/users").body.to_a
		!notified.empty? ? notified.map { |n| { id: n[0], next: n[1]['next'], tick: n[1]['tick'] } } : nil
	end
end