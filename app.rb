require 'bundler/setup'
require 'sinatra'
require 'csv'
require 'line/bot'
require 'nasa_apod'
require 'date'

get '/' do
  'hello world!'
end

def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
end

def nasa(today)
    client_nasa = NasaApod::Client.new(api_key: ENV['NASA_API_KEY']) #DEMO_KEY usage is limited.
    result = client_nasa.search(date: "#{today}") 
    return result.url
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
                if event.message['text'] =~ /nasa/
                    today = Date.today
                    p today
                    url = nasa(today)
                    space_image = {
                        type: 'image',
                        originalContentUrl: url,
                        previewImageUrl: url
                    }
                    client.reply_message(event['replyToken'], space_image)
                end
            end
        end
    end
  
    "OK"
end