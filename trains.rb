require 'uri'
require 'net/http'
require 'net/https'
require 'json'
require 'xmlsimple'

aurora_token = ""
darwin_token = ""
station_name = ""


@toSend = <<EOF
<?xml version="1.0"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="http://thalesgroup.com/RTTI/2014-02-20/ldb/" xmlns:ns2="http://thalesgroup.com/RTTI/2010-11-01/ldb/commontypes">
  <SOAP-ENV:Header>
    <ns2:AccessToken>
      <ns2:TokenValue>---Darwin-Token----</ns2:TokenValue>
    </ns2:AccessToken>
  </SOAP-ENV:Header>
  <SOAP-ENV:Body>
    <ns1:GetDepartureBoardRequest>
      <ns1:numRows>10</ns1:numRows>
      <ns1:crs>WVF</ns1:crs>
    </ns1:GetDepartureBoardRequest>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
EOF

uri = URI.parse("https://lite.realtime.nationalrail.co.uk:443/OpenLDBWS/ldb6.asmx")
https = Net::HTTP.new(uri.host,uri.port)
https.use_ssl = true
req = Net::HTTP::Post.new(uri.path, initheader = {'content-type' => 'text/xml;charset=UTF-8'})
req.body = @toSend
res = https.request(req)
#puts "Response #{res.code} #{res.message}: #{res.body}"


def get_state()
  url = "http://192.168.1.144:16021/api/v1/#{aurora_token}/state/"
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)

  request = Net::HTTP::Get.new(
    uri.request_uri, 
    'Content-Type' => 'application/json'
  )

  response = http.request(request)
  puts(response.body)
  return JSON.parse(response.body)
end 

def power(state)

power ="{
		\"on\": {
			\"value\": #{state}
		}
	}"

  url = "http://192.168.1.144:16021/api/v1/#{aurora_token}/state/"
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)

  request = Net::HTTP::Put.new(
    uri.request_uri, 
    'Content-Type' => 'application/json'
  )
  request.body = power

  response = http.request(request)
  puts(response.code)


end

def light_on(on_time)
	

	hue = nil
	if on_time == true
		hue = 100
	else 
		hue = 360
	end

	colour_change ="{
		\"hue\": {
			\"value\": #{hue}
		}
	}"

  url = "http://192.168.1.144:16021/api/v1/#{aurora_token}/state"
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)

  request = Net::HTTP::Put.new(
    uri.request_uri, 
    'Content-Type' => 'application/json'
  )
  request.body = colour_change

  response = http.request(request)
  puts(response.code)
  sleep(900)
  power(false)
end

@state = get_state()

power(true)

darwin_hash = XmlSimple.xml_in("#{res.body}")


darwin_hash["Body"].each do |a|
	a["GetDepartureBoardResponse"][0]["GetStationBoardResult"][0]["trainServices"].each do |trainServices|
		trainServices.each do |services|
			services[1].each do |service|
				if (service["destination"][0]["location"][0]["locationName"] == ["#{station_name}"]) && (service["std"][0] == "06:24")
					if service["etd"][0] == "On time"
						puts "----------------------------------------------------------"
						puts service["etd"][0]
						light_on(true)
					else
						light_on(false)
					end
				end

			end
		end
	end
end
