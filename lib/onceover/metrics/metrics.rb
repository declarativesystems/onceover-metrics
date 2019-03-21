class Onceover
  module Metrics
    module Metrics
      PUPPETFILE        = "Puppetfile"
      ENVIRONMENT_CONF  = "environment.conf"
      TOTALS_KEY        = :totals
      PUPPETFILE_KEY    = :puppetfile
      SITE_MODULES_KEY  = :site_modules

      def self.puppetfile
        data = File.readlines(PUPPETFILE)
        mod_count = data.grep(/^\s*mod /).size

        # inline definition barfs on keyname in variable
        stats = {}
        stats[PUPPETFILE_KEY] = {
          modules: mod_count
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

# overall code stats hash looks like this:
# {
#   "puppetfile": {
#     "modules": 63
#   },
#   "totals": {
#     "lines": 1070,
#     "comments": 572,
#     "code": 498,
#     "manifests": 25,
#     "templates": 1,
#     "files": 1,
#     "libs": 0,
#     "modules": 2
#   },
#   "site_modules": {
#     "site": {
#       "role": {
#         "manifests": {
#           "trusted_fact_classified.pp": {
#             "lines": 50,
#             "comments": 29,
#             "code": 21
#           },
#       "templates": 0,
#         "files": 0,
#         "libs": 0
#       },
      def self.code_stats
        # per module+file stats
        stats = {}

        # agregate stats
        stats[TOTALS_KEY] = {
          lines: 0,
          comments: 0,
          code: 0,
          manifests: 0,
          templates: 0,
          files: 0,
          libs: 0,
          modules: 0,
        }

        stats[SITE_MODULES_KEY] = {}

        # each scan path
        modpath_dirs.each { |modpath_dir|
          # ..but a scan path element may not exist...
          if Dir.exist? modpath_dir
            stats[SITE_MODULES_KEY][modpath_dir] = {}

            Dir.entries(modpath_dir).select { |mod_dir|
              File.directory? File.join(modpath_dir, mod_dir) and !(mod_dir =='.' || mod_dir == '..')
            }.each do |mod_dir|
              # each module dir
              stats[SITE_MODULES_KEY][modpath_dir][mod_dir] = {
                manifests: {},
                templates: 0,
                files: 0,
                libs: 0,
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
                    stats[SITE_MODULES_KEY][modpath_dir][mod_dir][:manifests][pp_file] = {
                      lines: lines,
                      comments: comments,
                      code: code,
                    }

                    stats[TOTALS_KEY][:lines] += lines
                    stats[TOTALS_KEY][:comments] += comments
                    stats[TOTALS_KEY][:code] += code
                    stats[TOTALS_KEY][:manifests] += 1
                  }
                end
                stats[SITE_MODULES_KEY][modpath_dir][mod_dir][TOTALS_KEY] = {}
                stats[SITE_MODULES_KEY][modpath_dir][mod_dir][TOTALS_KEY][:templates] = Dir["templates/**/*"].count { |file| File.file?(file) }
                stats[SITE_MODULES_KEY][modpath_dir][mod_dir][TOTALS_KEY][:libs] = Dir["lib/**/*"].count { |file| File.file?(file) }
                stats[SITE_MODULES_KEY][modpath_dir][mod_dir][TOTALS_KEY][:files] = Dir["files/**/*"].count { |file| File.file?(file) }

                stats[TOTALS_KEY][:templates] += stats[SITE_MODULES_KEY][modpath_dir][mod_dir][TOTALS_KEY][:templates]
                stats[TOTALS_KEY][:libs] += stats[SITE_MODULES_KEY][modpath_dir][mod_dir][TOTALS_KEY][:libs]
                stats[TOTALS_KEY][:files] += stats[SITE_MODULES_KEY][modpath_dir][mod_dir][TOTALS_KEY][:files]
                stats[TOTALS_KEY][:modules] += 1
              end
            end
          end
        }

        stats
  
      end

      def self.print_table(h, indent="")
        col_width = 50 - indent.length
        h.each do |k,v|
          printf("#{indent}%-#{col_width}s %10s\n", k, v)
        end
      end

      def self.format_report(stats, detailed)

        puts "----- [Puppetfile] -----"
        print_table(stats[PUPPETFILE_KEY])
        puts ""

        puts "----- [Puppet Code] -----"
        stats[SITE_MODULES_KEY].each do |modpath, modpath_data|
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
            puts "#{indent}manifests (#{mod_data[:manifests].length})"
            if detailed
              mod_data[:manifests].each { |pp_file, stats|

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
        print_table(stats[TOTALS_KEY])

      end

      def self.run(opts)
        stats = puppetfile.merge(code_stats)

        if opts[:format] == "json"
          pretty_json = JSON.pretty_generate(stats)
          puts pretty_json
        else
          # human mode
          format_report(stats, opts[:detailed])
        end


      end
    end
  end
end

