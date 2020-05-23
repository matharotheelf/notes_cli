# frozen_string_literal: true

require 'pry'
require 'pry-byebug'
require 'yaml'
require 'fileutils'

class Workspace
  ROOTH_PATH = __dir__
  CONFIG_PATH = File.join(ROOTH_PATH, 'config.yml')

  def initialize
    FileUtils.touch(CONFIG_PATH) unless File.file?(CONFIG_PATH)
  end

  def config
    YAML.safe_load(File.read(CONFIG_PATH))
  end

  def create_note(title, notebook)
    raise ArgumentError, 'no notebook specified' if !notebook || notebook.compact.empty?
    raise ArgumentError, 'no note title specified' if !title || title.empty?

    full_dir_path = File.join(notes_folder, current, notebook)
    return unless notebook_exists?(notebook) || create?('notebook')

    FileUtils.mkdir_p(full_dir_path)
    FileUtils.cd(full_dir_path)
    FileUtils.touch("#{title}.md")
    FileUtils.cd(File.join(notes_folder, current))

    puts current.to_s
    puts '----------------'
    puts "Added '#{title}' to your #{notebook.join('/')} notebook"
  end

  def delete_note(title, notebook)
    raise ArgumentError, 'no notebook specified' if !notebook || notebook.compact.empty?
    raise ArgumentError, 'no note title specified' if !title || title.empty?

    full_dir_path = File.join(notes_folder, current, notebook)
    FileUtils.cd(full_dir_path)
    FileUtils.rm("#{title}.md")
    FileUtils.cd(File.join(notes_folder, current))

    puts current.to_s
    puts '----------------'
    puts "Deleted '#{title}' from your #{notebook.join('/')} notebook"
  end

  def current
    return config['workspace'] if config && config['workspace']

    raise StandardError, 'Please set your workspace'
  end

  def notes_folder
    return config['notes_folder'] if config && config['notes_folder']

    raise StandardError, 'Please set your notes_folder'
  end

  def switch_workspace(workspace)
    return unless workspace_exists?(workspace) || create?('workspace')

    update_entry('workspace', workspace)
  end

  def workspace_exists?(workspace)
    Dir.glob("#{notes_folder}/*/")
       .select { |entry| File.directory? entry }
       .map { |full_path| File.basename(full_path) }
       .include?(workspace)
  end

  def notebook_exists?(notebook)
    Dir.glob("#{notes_folder}/#{current}/*/")
       .select { |entry| File.directory? entry }
       .map { |full_path| File.basename(full_path) }
       .include?(notebook)
 end

  def create?(resource)
    puts "This #{resource} does not currently exist and will be created, "\
         'do you wish to continue? [y/N]'
    STDIN.gets.chomp == 'y'
  end

  def update_entry(key, value)
    current_config = config
    current_config ? current_config[key] = value.strip.chomp : current_config = { key => value }
    File.open(CONFIG_PATH, 'w') { |file| file.truncate(0) }
    File.open(CONFIG_PATH, 'r+') do |f|
      YAML.dump(current_config, f)
    end
  end
end
