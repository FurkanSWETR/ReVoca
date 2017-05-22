require 'json'
require 'cgi'

class Translator
	def self.translate(text, klang, llang)
		uri = URI.parse("http://www.transltr.org/api/translate?text=" + CGI.escape(text) + "&to=" + klang.to_s + "&from=" + llang.to_s)
		response = JSON.load(Net::HTTP.get_response(uri).body)
		return response
	end
end