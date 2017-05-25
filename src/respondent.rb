require 'aws-sdk'

require_relative 'fb'
require_relative 'response'

class Respondent
	@fb
	@chat_id
	@message
	@r

	def initialize(message)
		firebase_url = ENV.fetch('FIREBASE_URL')
		@fb = FB.new(firebase_url)
		@message = message.text
		@chat_id = message.chat.id.to_s

		@r = Response.new(@fb, message)
	end

	def form_error()
		@r.error()
	end

	def form_response()
		case @message
		when '/cancel'
			@r.cancel()
		when '/creator'
			@r.creator()
		when '/help'
			@r.help()
		when '/play_select'
			@r.play_select_question()
		when '/play_translate'		
			@r.play_translate_question()
		when '/save'
			@r.save()
		when '/settings_language'
			@r.settings_language_question()
		when '/settings_notification'
			@r.settings_notification_question()
		when '/settings_sleep'		
			@r.settings_sleep()
		when '/start'
			@r.start()
		when '/vocabulary_delete'
			@r.vocabulary_delete_question()
		when '/vocabulary_list'
			@r.vocabulary_list()
		when '/vocabulary_new'
			@r.vocabulary_new()
		when '/vocabulary_switch'
			@r.vocabulary_switch_question()
		when '/word_add'
			@r.word_add()
		when '/word_list'
			@r.word_list()
		when '/word_translate'
			@r.word_translate_question()
		else
			state = @fb.state.now(@chat_id)
			case state     
			when 'games'
				@r.games()
			when 'games_select'
				@r.play_select_answer()
			when 'games_translate'
				@r.play_translate_answer()
			when 'idle'
				@r.idle()
			when 'settings'
				@r.settings()
			when 'settings_language'
				@r.settings_language_answer()
			when 'settings_notify'
				@r.settings_notification_answer()
			when 'settings_sleep_daytime'
				@r.settings_sleep_daytime()
			when 'settings_sleep_hours'
				@r.settings_sleep_hours()
			when 'vocabularies'
				@r.vocabularies
			when 'voc_delete'
				@r.vocabulary_delete_answer()
			when 'voc_new_llang'
				@r.vocabulary_new_llang()
			when 'voc_new_klang'		
				@r.vocabulary_new_klang()
			when 'voc_switch'
				@r.vocabulary_switch_answer()
			when 'words'
				@r.words()
			when 'word_add_word'
				@r.word_add_word()
			when 'word_add_translation'
				@r.word_add_translation()
			when 'word_add_question'
				@r.word_add_question()
			when 'word_translate'
				@r.word_translate_answer()
			else
				@r.unknown()
			end
		end
	end
end