#!/usr/bin/env ruby

# == Synopsis
#
# collect_coeffs.rb:: Create tarball of the CRTM coefficients.
#
# == Usage
#
# collect_coeffs.rb [-h]
#
# -h, --help:
#    you're looking at it
#
#    
# Written by:: Paul van Delst, 02-Feb-2009 (paul.vandelst@noaa.gov)
#

require 'getoptlong'
require 'rdoc/usage'
require 'fileutils'
require 'sensorinfo'

# Define constants and defaults
FIXFILE_ROOT = ENV['CRTM_FIXFILE_ROOT']
FIXFILE_SENSORINFO = "SensorInfo.release"
FIXFILE_FORMAT = [{:name=>"Big_Endian",:ext=>"bin"},
                  {:name=>"Little_Endian",:ext=>"bin"},
                  {:name=>"netCDF",:ext=>"nc"}]
FIXFILE_TAR = "CRTM_Coefficients"
FIXFILE_INFO = [{:name=>"TauCoeff",
                 :subdirs=>["Infrared/ORD","Infrared/PW","Microwave/Rosenkranz"]},
                {:name=>"SpcCoeff",
                 :subdirs=>["Infrared","Microwave/No_AC","Microwave/AAPP_AC"]},
                {:name=>"AerosolCoeff",
                 :subdirs=>[]},
                {:name=>"CloudCoeff",
                 :subdirs=>[]},
                {:name=>"EmisCoeff",
                 :subdirs=>[]}]
      
              
puts("---> Collecting coefficient files...")

begin
  FileUtils.chdir(FIXFILE_ROOT) do

    # Read the SensorInfo file
    sensorinfo = SensorInfo::Node.load(FIXFILE_SENSORINFO)

    # Create the main directory
    FileUtils.rm_rf(FIXFILE_TAR,:secure=>true) if File.exists?(FIXFILE_TAR)
    FileUtils.mkdir(FIXFILE_TAR)

    # Begin linking    
    FileUtils.chdir(FIXFILE_TAR) do
    
      # Loop over each type of Coeff file
      FIXFILE_INFO.each do |type|
        FileUtils.mkdir(type[:name])
        type_root = "#{FIXFILE_ROOT}/#{type[:name]}"
        FileUtils.chdir(type[:name]) do
        
          # Loop over each type of Coeff format
          FIXFILE_FORMAT.each do |format|
            FileUtils.mkdir(format[:name])
            FileUtils.chdir(format[:name]) do
            
              if type[:name] == "TauCoeff" || type[:name] == "SpcCoeff"
                # TauCoeff and SpcCoeff special case as they are sensor specific
                type[:subdirs].each do |subdir|
                  sensorinfo.each do |s|
                    sensor_id = s.first
                    coeff_file = "#{sensor_id}.#{type[:name]}.#{format[:ext]}"
                    src_dir = "#{type_root}/#{subdir}/#{format[:name]}"
                    # Skip link if file doesn't exist
                    if File.exists?("#{src_dir}/#{coeff_file}")
                      puts("linking in #{coeff_file} from #{src_dir}")
                      FileUtils.ln_sf("#{src_dir}/#{coeff_file}", coeff_file)
                    end
                  end
                end
              else
                # Other Coeff types do not have subdirs
                coeff_file = "#{type[:name]}.#{format[:ext]}"
                src_dir = "#{type_root}/#{format[:name]}"
                # Skip link if file doesn't exist
                if File.exists?("#{src_dir}/#{coeff_file}")
                  puts("linking in #{coeff_file} from #{src_dir}")
                  FileUtils.ln_sf("#{src_dir}/#{coeff_file}", coeff_file)
                end
              end
            end
          end
        end
      end
    end
  end
  
  # Create a tarball of the created directory
  system("tar cvhf #{FIXFILE_TAR}.tar ./#{FIXFILE_TAR}")
  system("gzip -f #{FIXFILE_TAR}.tar")
  FileUtils.rm_rf("./#{FIXFILE_TAR}")
  
rescue Exception => error_message
  puts "ERROR: #{error_message}"
  exit 1
end

