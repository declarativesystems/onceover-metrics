require 'yaml'
require 'csv'
require 'deep_merge'

class Onceover
  module Metrics
    module Metrics
      PUPPETFILE            = "Puppetfile"
      ENVIRONMENT_CONF      = "environment.conf"
      TOTALS_KEY            = :totals
      PUPPETFILE_KEY        = :puppetfile
      SITE_MODULES_KEY      = :site_modules
      HIERA_KEY             = :hiera
      YAML_KEY              = :yaml
      FILES_KEY             = :files
      TEMPLATES_KEY         = :templates
      LINES_KEY             = :lines
      COMMENTS_KEY          = :comments
      MANIFESTS_KEY         = :manifests
      LIBS_KEY              = :libs
      MODULES_KEY           = :modules
      CODE_KEY              = :code
      HIERA_FILES_KEY       = :hiera_yaml_files
      HIERA_KEYS_UNIQUE     = :hiera_keys_unique
      HIERA_TOP_LEVEL_KEYS  = :top_level_keys


      def self.puppetfile
        data = File.readlines(PUPPETFILE)
        mod_count = data.grep(/^\s*mod /).size

        # inline definition barfs on keyname in variable
        stats = {}
        stats = {
          TOTALS_KEY => {
            MODULES_KEY => mod_count,
          }
        }

        stats
      end

      def self.modpath_dirs
        dirs = []
        modulepath_line = File.readlines(ENVIRONMENT_CONF).grep(/^\s*modulepath\s*=/)
        modulepath_value = modulepath_line[0].split(/=/)[1]
        modulepath_value.split(":").reject { |e|
          ! (e =~ /\w+/)
        }.each { |e| 
          dirs << e.strip
        }

        dirs
      end

      def self.code_stats
        # per module+file stats
        stats = {
          # agregate stats
          TOTALS_KEY => {
            LINES_KEY => 0,
            COMMENTS_KEY => 0,
            CODE_KEY => 0,
            MANIFESTS_KEY => 0,
            TEMPLATES_KEY => 0,
            FILES_KEY => 0,
            LIBS_KEY => 0,
            MODULES_KEY => 0,
          },

          # per module scan path stats
          CODE_KEY => {
            SITE_MODULES_KEY => {},
          },
        }

        # each scan path
        modpath_dirs.each { |modpath_dir|
          # ..but a scan path element may not exist...
          if Dir.exist? modpath_dir
            stats[CODE_KEY][SITE_MODULES_KEY][modpath_dir] = {}

            Dir.entries(modpath_dir).select { |mod_dir|
              File.directory? File.join(modpath_dir, mod_dir) and !(mod_dir =='.' || mod_dir == '..')
            }.each do |mod_dir|
              # each module dir
              stats[CODE_KEY][SITE_MODULES_KEY][modpath_dir][mod_dir] = {
                MANIFESTS_KEY => {},
              }


              Dir.chdir "#{modpath_dir}/#{mod_dir}" do
                # each puppet module

                Dir.chdir "manifests" do
                  # each puppet manifest
                  Dir["**/*.pp"].each { |pp_file|
                    data                 = File.readlines(pp_file)
                    lines                = data.size
                    comments             = data.grep(/^\s*#/).size
                    code                 = lines - comments
                    stats[CODE_KEY][SITE_MODULES_KEY][modpath_dir][mod_dir][MANIFESTS_KEY][pp_file] = {
                      LINES_KEY => lines,
                      COMMENTS_KEY => comments,
                      CODE_KEY => code,
                    }

                    # update the global total counts
                    stats[TOTALS_KEY][LINES_KEY] += lines
                    stats[TOTALS_KEY][COMMENTS_KEY] += comments
                    stats[TOTALS_KEY][CODE_KEY] += code
                    stats[TOTALS_KEY][MANIFESTS_KEY] += 1
                  }
                end

                stats[CODE_KEY][SITE_MODULES_KEY][modpath_dir][mod_dir][TOTALS_KEY] = {
                  TEMPLATES_KEY => (Dir["templates/**/*"].count { |file| File.file?(file)}),
                  LIBS_KEY => (Dir["lib/**/*"].count { |file| File.file?(file)}),
                  FILES_KEY => (Dir["files/**/*"].count { |file| File.file?(file)}),
                }

                stats[TOTALS_KEY][TEMPLATES_KEY] += stats[CODE_KEY][SITE_MODULES_KEY][modpath_dir][mod_dir][TOTALS_KEY][TEMPLATES_KEY]
                stats[TOTALS_KEY][LIBS_KEY] += stats[CODE_KEY][SITE_MODULES_KEY][modpath_dir][mod_dir][TOTALS_KEY][LIBS_KEY]
                stats[TOTALS_KEY][FILES_KEY] += stats[CODE_KEY][SITE_MODULES_KEY][modpath_dir][mod_dir][TOTALS_KEY][FILES_KEY]
                stats[TOTALS_KEY][MODULES_KEY] += 1
              end
            end
          end
        }

        stats
  
      end

      # assumes hiera data in /data
      def self.hiera
        stats = {
          HIERA_KEY => {},
          TOTALS_KEY => {},
          HIERA_KEY => {
            YAML_KEY => {},
          },
        }
        total_lines = 0
        yaml_files = Dir["data/**/*.yaml"]

        # parse each file to count top-level keys
        top_level_keys = []
        yaml_files.each do |yaml_file|

          # count lines that are whitespace or comments
          lines = File.readlines(yaml_file).reject{|e| e =~ /^\s*(\s*|#.*)$/}.length

          data = YAML.load_file(yaml_file)
          stats[HIERA_KEY][YAML_KEY][yaml_file] = {
            LINES_KEY => lines,
          }

          total_lines += lines
          if data
            # there may be files with no keys...
            stats[HIERA_KEY][YAML_KEY][yaml_file][HIERA_TOP_LEVEL_KEYS] = data.keys.length
            top_level_keys << data.keys
          end

        end

        stats[TOTALS_KEY] = {
          HIERA_FILES_KEY   => yaml_files.length,
          HIERA_KEYS_UNIQUE => top_level_keys.uniq.length,
          LINES_KEY         => total_lines,
        }

        stats
      end


      def self.print_table(h, indent="")
        col_width = 50 - indent.length
        h.each do |k,v|
          kf = k.to_s.gsub(/_/, ' ')
          printf("#{indent}%-#{col_width}s %10s\n", kf, v)
        end
      end

      def self.format_report(stats, detailed)
        if detailed
          puts "----- [Hiera] -----"
          stats[HIERA_KEY][YAML_KEY].each do |yaml_file, data|
            puts yaml_file
            print_table(data, "  ")
          end
          puts ""
        end

        puts "----- [Puppet Code] -----"
        stats[CODE_KEY][SITE_MODULES_KEY].each do |modpath, modpath_data|
          # each path element
          puts "#{modpath}"

          modpath_data.each do | mod_name, mod_data |
            # each module
            indent = "  "
            puts "#{indent}#{mod_name}"

            indent = "    "
            # per-module metrics
            print_table(mod_data[TOTALS_KEY], indent)

            # per-manifest stats
            print_table({MANIFESTS_KEY => mod_data[MANIFESTS_KEY].length}, indent)

            if detailed
              mod_data[MANIFESTS_KEY].each { |pp_file, stats|

                indent = "      "
                puts "#{indent}#{pp_file}"

                indent = "        "
                print_table(stats, indent)
              }
            end
          end
        end
        puts ""

        puts "***** [TOTALS] *****"
        stats[TOTALS_KEY].each do |k,v|
          puts k
          print_table(v, "  ")
        end


      end

      def self.run(opts)
        puppetfile = puppetfile()
        code_stats = code_stats()
        hiera = hiera()

        stats = {
          CODE_KEY => code_stats[CODE_KEY],
          HIERA_KEY => hiera[HIERA_KEY],
          TOTALS_KEY => {
            PUPPETFILE_KEY => puppetfile[TOTALS_KEY],
            CODE_KEY => code_stats[TOTALS_KEY],
            HIERA_KEY => hiera[TOTALS_KEY],
            TOTALS_KEY => {
              LINES_KEY => code_stats[TOTALS_KEY][LINES_KEY] + hiera[TOTALS_KEY][LINES_KEY],
              MODULES_KEY => puppetfile[TOTALS_KEY][MODULES_KEY] + code_stats[TOTALS_KEY][MODULES_KEY]
            }
          },
        }

        if opts[:format] == "json"
          pretty_json = JSON.pretty_generate(stats)
          puts pretty_json
        elsif opts[:format] == "csv"

          csv_string = CSV.generate do |csv|
            stats[TOTALS_KEY].each { |k,v|
              csv << [k]
              v.to_a.each {|elem| csv << elem}
              csv << []
            }
          end

          puts csv_string
        else
          # human mode
          format_report(stats, opts[:detailed])
        end

      end
    end
  end
end

