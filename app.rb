require 'bundler/setup'
require 'sinatra'
require 'line/bot'
require 'nasa_apod'
require 'net/http'
require 'json'

get '/' do
  'hello world!'
end

def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
end

def nasa
    uri = URI.parse('https://api.nasa.gov/planetary/apod?api_key=4ftlGyoLKwGDdwKVvco7nkWzqC1520tknZM28pKS')
    json = Net::HTTP.get(uri)
    data = JSON.parse(json)
    return data["url"], data["date"], data["title"]
end

post '/callback' do
    body = request.body.read
  
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      halt 400, {'Content-Type' => 'text/plain'}, 'Bad Request'
    end
  
    events = client.parse_events_from(body)
  
    events.each do |event|
        case event
        when Line::Bot::Event::Message
            case event.type
            when Line::Bot::Event::MessageType::Text
                if event.message['text'] == "今日の天文写真は？"
                    today = Date.today
                    puts today
                    url = nasa[0]
                    date = nasa[1]
                    title = nasa[2]
                    space_image = {
                        type: 'image',
                        originalContentUrl: url,
                        previewImageUrl: url
                    }
                    message = {
                        type: 'text',
                        text: "#{date}\n#{title}"
                    }
                    message = {
                        type: 'text',
                        text: "https://www.youtube.com/watch?v=aKK7vS2CHC8"
                    }
                    client.reply_message(event['replyToken'], [space_image, message])
                end
            end
        end
    end
  
    "OK"
end