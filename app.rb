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
    iFileName = "image_url.csv"
    client_nasa = NasaApod::Client.new(api_key: ENV['NASA_API_KEY']) #DEMO_KEY usage is limited.
    result = client_nasa.search(date: "#{today}") 
    uri = result.url
    text = CSV.open("image_url.csv",'a')
    text.puts [uri]
    image_csv = CSV.read(iFileName, headers: true).map(&:to_hash)
    # find_data = image_csv.find {|x| x["date"] == "#{today}"}
    p image_csv
    # if find_data == nil
    #     client_nasa = NasaApod::Client.new(api_key: ENV['NASA_API_KEY']) #DEMO_KEY usage is limited.
    #     result = client_nasa.search(date: "#{today}") #You can also pass in a Ruby Date object.
    #     p result.url
    #     text = CSV.open(iFileName,'a')
    #     text.puts ["#{today}","#{result.url}"]
    #     return result.url
    # else
    #     return find_data["image_url"]
    # end
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
                    today = Date.today - 1   # NASA(US)との時差のため昨日の日付にする
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