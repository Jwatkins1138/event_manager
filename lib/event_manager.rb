require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone)
  if phone.match?(/\D/)
    phone.to_s.gsub!(/[^0-9]/,"")
  end
  if phone.length < 10
    phone = "no valid phone number."
  elsif phone.length == 11 && phone[0] == "1"
    phone = phone.slice(1, 10)
  elsif phone.length > 10
    phone = "no valid phone number."
  end
  phone
end

def legislators_by_zipcode(zip)

  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    )
    legislators = legislators.officials

    legislator_names = legislators.map(&:name)

    legislator_names.join(", ")
  
  rescue
    "error finding legislators with provided address."
  
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end



puts 'Event Manager Initialized'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

hours = Hash.new(0)
days = Hash.new(0)

contents.each do |row|
  id = row[0]

  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  # save_thank_you_letter(id, form_letter)

  phone = clean_phone_number(row[:homephone].to_s)

  date = Time.strptime(row[:regdate], '%m/%d/%y %k')

  hours[date.hour] += 1

  days[date.wday] += 1

end

puts hours.sort_by {|k,v| -v}.to_h

puts days.sort_by {|k,v| -v}.to_h