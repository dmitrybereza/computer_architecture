# frozen_string_literal: true

require 'time'
require 'find'
require 'pathname'

HELP_PARAMETR = '/?'
DELIMETER = ' '
ATTRIBUTES_START = '/A:['
ATTRIBUTES_END = ']'
EMPTY_PLACE = ''
DEFAULT_DIR = __dir__
ABSOLUTE_PATH = 'absolute-path'
SKIP_ATTRIBUTE = 'skip-hidden'
HIDDEN_ATTRIBUTE = '/.'

def print_help
  puts 'Welcome to help!'
  puts "  You can start programm with arguments:\n\n"
  puts '  1 parametr: catalog path (default: current path)'
  puts '  2 parametr filename in catalog (default: all files)'
  puts '  3 parametr new creation time'
  puts "  4 parametr file attributes '/A:[attr1, attr2, ...]'"
  puts '  Admissible attributes: \'absolute-path skip-hidden\''
end

def incorrect_attributes
  puts 'Input attributes in correct format!'

  exit 1
end

def wrong_folder_name
  puts 'There is no folder with with path'

  exit 1
end

def wrong_filename
  puts 'There is no file with this name in folder'

  exit 1
end

def wrong_date_format
  puts 'Invalid date format'

  exit 1
end

def wrong_attribute
  puts 'Invalid attribute'

  exit 1
end

def help
  return unless ARGV.include?(HELP_PARAMETR)

  print_help
  exit 0
end

def attributes
  attributes = ARGV.select { |element| element.include?(ATTRIBUTES_START) }.first.to_s
  return if attributes.empty?

  incorrect_attributes if attributes[-1] != ATTRIBUTES_END
  attributes = attributes.tr(ATTRIBUTES_START, EMPTY_PLACE)
  attributes = attributes.tr(ATTRIBUTES_END, EMPTY_PLACE)

  return wrong_attribute unless attributes.include?(SKIP_ATTRIBUTE)

  ARGV.pop
  attributes
end

def find_folder_path(attributes)
  pathname = attributes&.include?(ABSOLUTE_PATH) ? Dir.home + ARGV.first : ARGV.first
  pathname = pathname.nil? ? DEFAULT_DIR : pathname
  path = Pathname.new(pathname)
  return Pathname.new(DEFAULT_DIR) if path.file?

  return wrong_folder_name unless path.directory?

  ARGV.shift
  path
end

def find_file(path)
  return if ARGV.first.nil? || ARGV.count == 1

  return wrong_filename unless Dir.children(path).include?(ARGV.first)

  path += ARGV.first
  ARGV.shift
  path
end

def find_date_from_args
  ARGV.each do |argument|
    begin
      return { date: Time.parse(argument), argument: argument }
    rescue TypeError, ArgumentError
      next
    end
  end
end

def find_date
  date = find_date_from_args

  return wrong_date_format if date.class == Array

  ARGV.delete(date[:argument])
  date[:date]
end

def change_dir_files_date(folder:, date:, attributes:)
  Find.find(folder) do |path|
    next if attributes == SKIP_ATTRIBUTE && path.include?(HIDDEN_ATTRIBUTE)

    File.utime(File.atime(path), date, path)
  end
end

def change_date(date:, folder:, file:, attributes:)
  return change_dir_files_date(folder: folder, date: date, attributes: attributes) if file.nil?

  File.utime(File.atime(file), date, file)
end

help
date = find_date
file_attributes = attributes
folder_path = find_folder_path(file_attributes)
file_path = find_file(folder_path)
change_date(date: date, folder: folder_path, file: file_path, attributes: file_attributes)
