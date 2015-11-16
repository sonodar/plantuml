require 'digest/sha2'

module PlantumlHelper

  SOURCE_EXT = '.pu'.freeze

  ALLOWED_FORMATS = {
    'png' => { type: 'png', ext: '.png', content_type: 'image/png', inline: true },
    'svg' => { type: 'svg', ext: '.svg', content_type: 'image/svg+xml', inline: true }
  }.freeze

  def self.construct_cache_key(key)
    ['plantuml', Digest::SHA256.hexdigest(key.to_s)].join('_')
  end

  def self.check_format(frmt)
    ALLOWED_FORMATS.fetch(frmt, ALLOWED_FORMATS['png'])
  end

  def self.plantuml_file(basename, extension = SOURCE_EXT)
    File.join(Rails.root, 'files', "#{basename}#{extension}")
  end

  def self.output_source_file(file, text)
    File.open(file, 'w') { |w| w.write "@startuml\n#{text}\n@enduml\n" }
  end

  def self.exec_plantuml(frmt, source_file)
    output_type = frmt[:type]
    settings_binary = Setting.plugin_plantuml['plantuml_binary_default']
    cmd = "#{settings_binary} -charset UTF-8 -t'#{output_type}' #{source_file}"
    system(cmd)
  end

  def self.plantuml(text, args)

    # Generate basename
    basename = construct_cache_key(text)

    frmt = check_format(args)

    # If exists image file then finish.
    if File.file?(plantuml_file(basename, frmt[:ext]))
      return basename
    end

    source_file = plantuml_file(basename)
    
    # If not exists #{basename}.pu file then create #{basename}.pu file.
    unless File.file?(source_file)
      output_source_file(source_file, text)
    end

    unless exec_plantuml(frmt, source_file)
      raise "PlantUML execution failed."
    end

    basename

  end

end
