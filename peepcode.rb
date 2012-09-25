# PeepCode Downloader
#
# Download every screencast from PeepCode that you have access to
#
# by Jamie Rumbelow
# http://jamierumbelow.net

require 'rubygems'
require 'mechanize'

puts "PeepCode Downloader"
puts "-------------------\n"

# Fetch the user's input
print "Email: "
email = gets.chomp

print "Password: "
password = gets.chomp

print "Download directory (NO trailing slash) [~/Movies/PeepCode]: "
directory = gets.chomp

directory = '~/Movies/PeepCode' if directory.empty?

# Ensure that the download directory exists and is writable...
path = File.expand_path directory

Dir.mkdir(path) unless File.directory? path

unless File.writable?(path)
  puts "Your download directory is unwritable!"
  exit 1
end

# Load the login page
print "\n"
puts "Loading PeepCode..."

agent = Mechanize.new
page = agent.get 'http://peepcode.com/login'

# Log in to the site
form = page.forms.first
form.email = email
form.password = password

page = agent.submit form, form.buttons.first
page = page.link_with(:text => 'Screencasts').click

# Find every link to a product (screencast/video)
links = agent.page.links.find_all { |l| l.href =~ /^\/products\/(.*)/ }

# Loop through each link and begin to download!
links.each do |link|
  page = link.click

  # don't download Peepcode product bundles
  if page.search('.product_title td').children.any?
    screencast_name = page.search('.product_title td').children.first.text.strip

    # download .mov file
    mov_download_link = page.links.find { |l| l.href =~ /\.mov_z$/ }
  
    unless File.exists?("#{path}/#{screencast_name}.zip") || mov_download_link.nil?
      puts "Downloading '#{screencast_name}'!"

      agent.pluggable_parser.default = Mechanize::Download
      agent.get(mov_download_link.href).save("#{path}/#{screencast_name}.zip")
      agent.pluggable_parser.default = Mechanize::File
    end

    # download .pdf file
    pdf_download_link = page.links.find { |l| l.href =~ /\.pdf$/ }

    unless File.exists?("#{path}/#{screencast_name}.pdf") || pdf_download_link.nil?
      puts "Downloading '#{screencast_name}' PDF!"

      agent.pluggable_parser.default = Mechanize::Download
      agent.get(pdf_download_link.href).save("#{path}/#{screencast_name}.pdf")
      agent.pluggable_parser.default = Mechanize::File
    end
  end
end
