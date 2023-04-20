require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def open_csv
  contents = CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol
  )
end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phonenumbers(phonenumber)
  if phonenumber.length < 10 || phonenumber.length > 11
    "Phone number wasn't entered correctly so we can not give you information"
  elsif phonenumber.length == 11
    if phonenumber[0] == 1
      phonenumber = phonenumber.shift
    else
      "Phone number wasn't entered correctly so we can not give you information"
    end
  else
    phonenumber
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def common_hours
  contents = open_csv
  hour_array = []
  contents.each do |row|
    registration_time = Time.strptime(row[:regdate], "%m/%d/%Y %k:%M")
    hour_array = hour_array.push(registration_time.hour)
  end

  most_common_hour = hour_array.reduce(Hash.new(0)) do |hash, hour|
    hash[hour] += 1
    hash
  end
  most_common_hour.sort_by {|k, v| v}.reverse.to_h
end

puts 'EventManager initialized.'


template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

open_csv.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phonenumber = clean_phonenumbers(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end

puts "The common hours are #{common_hours.keys[0]}:00, #{common_hours.keys[1]}:00, #{common_hours.keys[2]}:00"
puts "Nothing yet bish"