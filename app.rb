require 'bundler/setup'
require 'sinatra'
require 'line/bot'
require 'nasa_apod'
require 'net/http'
require 'json'
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

def nasa(date)
    api_key = ENV["NASA_API_KEY"]
    if date == 0
        uri = URI.parse("https://api.nasa.gov/planetary/apod?api_key=#{api_key}")
    else
        uri = URI.parse("https://api.nasa.gov/planetary/apod?api_key=#{api_key}&date=#{date}")
    end
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
                    data = nasa(0)
                    url = data[0]
                    date = data[1]
                    title = data[2]
                    reply_image(event, url, date, title)
                elsif event.message['text'] == "あの日の天文写真は？"
                    today = Date.today
                    client.reply_message(event['replyToken'], select_date(today))
                end
            end
        when Line::Bot::Event::Postback
            puts "ok"
            user_date = event['postback']['params']['date']
            data = nasa(user_date)
            url = data[0]
            date = data[1]
            title = data[2]
            reply_image(event, url, date, title)
        end
    end
  
    "OK"
end

def select_date(today)
    {
    "type": "template",
        "altText": "this is a buttons template",
        "template": {
            "type": "buttons",
            "title": "Please select a date",
            "text": "いつの天文写真を見ますか？",
            "actions": [
                {
                  "type": "datetimepicker",
                  "label": "select date",
                  "mode": "date",
                  "data": "action=datetemp&selectId=1",
                  "max": today,
                  "min": "1995-06-20"
                }
            ]
        }
    }
end

def reply_image(event, url, date, title)
    if url =~ /jpg/
        space_image = {
            type: 'image',
            originalContentUrl: url,
            previewImageUrl: url
        }
    else
        space_image = {
            type: 'text',
            text: url
        }
    end
    message = {
        type: 'text',
        text: "#{date}\n#{title}"
    }
    client.reply_message(event['replyToken'], [space_image, message])
end
