#!/usr/bin/env ruby

require 'net/https'
require "uri"

# get token and channels
user = IO.popen("whoami", "r+").gets.chomp
program = ARGV[0].to_s
dotfile = "/Users/#{user}/.rssts"

lines = []
if File.exist?(dotfile) then
  lines = File.read(dotfile).rstrip.split(/\r?\n/).map do |line|
    line.chomp
  end
end

if lines.length < 2 then
  p "Needs token and channels"
  exit 1
end

token = lines[0].chomp
channels = lines[1].chomp

# capture png file
tmpfile = "/tmp/image_upload#{$$}.png"
imagefile = ARGV[1]

if imagefile && File.exist?(imagefile) then
  system "sips -s format png \"#{imagefile}\" --out \"#{tmpfile}\""
else
  system "screencapture -i \"#{tmpfile}\""
  if File.exist?(tmpfile) then
    system "sips -d profile --deleteColorManagementProperties \"#{tmpfile}\""  
    dpiWidth    = `sips -g dpiWidth "#{tmpfile}" | awk '/:/ {print $2}'`
    dpiHeight   = `sips -g dpiHeight "#{tmpfile}" | awk '/:/ {print $2}'`
    pixelWidth  = `sips -g pixelWidth "#{tmpfile}" | awk '/:/ {print $2}'`
    pixelHeight = `sips -g pixelHeight "#{tmpfile}" | awk '/:/ {print $2}'`
    if (dpiWidth.to_f > 72.0 and dpiHeight.to_f > 72.0) then
        width  =  pixelWidth.to_f * 72.0 / dpiWidth.to_f
        height =  pixelHeight.to_f* 72.0 / dpiHeight.to_f
        system "sips -s dpiWidth 72 -s dpiHeight 72 -z #{height} #{width} \"#{tmpfile}\""
    end
  end
end

if !File.exist?(tmpfile) then
  exit 1
end

imagedata = File.read(tmpfile)
File.delete(tmpfile)

# upload
boundary = '----BOUNDARYBOUNDARY----'

data = <<EOF
--#{boundary}\r
content-disposition: form-data; name="token"\r
\r
#{token}\r
--#{boundary}\r
content-disposition: form-data; name="channels"\r
\r
#{channels}\r
--#{boundary}\r
content-disposition: form-data; name="file"; filename="screenshot"\r
\r
#{imagedata}\r
--#{boundary}--\r
EOF

header ={
  'Content-Length' => data.length.to_s,
  'Content-type' => "multipart/form-data; boundary=#{boundary}",
}


uri = URI.parse("https://slack.com/")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
res = http.post('/api/files.upload', data, header)
