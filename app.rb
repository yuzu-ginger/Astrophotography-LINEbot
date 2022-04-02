require 'bundler/setup'
require 'sinatra'
require 'line/bot'
require 'nasa_apod'

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
    client_nasa = NasaApod::Client.new(api_key: "fc7zkkCXmyQbyymO85ZKQFWwav9ypg4xlBbVvRg2") #DEMO_KEY usage is limited.
    result = client_nasa.search(date: "2022-03-19") #You can also pass in a Ruby Date object.
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
                url = nasa
            space_image = {
                type: "image",
                originalContentUrl: url,
                previewImageUrl: url
            }
            message = {
                type: "text",
                text: nasa
            }
            client.reply_message(event['replyToken'], [space_image, message])
            end
        end
    end
  
    "OK"
end