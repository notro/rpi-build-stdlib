# not needed when building on the Raspberry Pi
unless uname_m == 'armv6l'
  package :rpi_tools do
    ENV['RPI_TOOLS_BRANCH'] ||= 'master'
    env_store 'RPI_TOOLS_SHA' do
      github_get_head('raspberrypi/tools', ENV['RPI_TOOLS_BRANCH'])
    end
    github_tarball 'raspberrypi/tools', 'tools', ENV['RPI_TOOLS_SHA']
  end
else
  package :rpi_tools
end

package :rpi_firmware do |t|
  # if RPI_FIRMWARE_SHA is not set, find the latest commit on
  #   branch RPI_FIRMWARE_BRANCH (defaults to 'master'),
  #   and store this value for later runs
  ENV['RPI_FIRMWARE_BRANCH'] ||= 'master'
  env_store 'RPI_FIRMWARE_SHA' do
    github_get_head('raspberrypi/firmware', ENV['RPI_FIRMWARE_BRANCH'])
  end

  # source
  github_tarball 'raspberrypi/firmware', 'firmware', ENV['RPI_FIRMWARE_SHA']

  task :install do
    src = workdir 'firmware'
    dst = workdir 'out'

		# Using FileList gives a hard to read output with all the files listed on the command line
    sh "cp -r #{src}/boot/* #{dst}/"

    mkdir_p(dst + "/vc/sdk/opt/vc")
		cp_r(src + "/opt/vc/include/", dst + "/vc/sdk/opt/vc/")
		cp_r(src + "/opt/vc/src/",  dst + "/vc/sdk/opt/vc/")
		# delete due to size 30MB
		rm_rf(dst + "/vc/sdk/opt/vc/src/hello_pi/hello_video/test.h264")

		mkdir_p(dst + "/vc/softfp/opt/vc")
		cp_r(src + "/opt/vc/LICENCE", dst + "/vc/softfp/opt/vc")
		cp_r(src + "/opt/vc/bin/", dst + "/vc/softfp/opt/vc")
		cp_r(src + "/opt/vc/lib/", dst + "/vc/softfp/opt/vc")
		cp_r(src + "/opt/vc/sbin/", dst + "/vc/softfp/opt/vc")

		mkdir_p(dst + "/vc/hardfp/opt/vc")
		cp_r(src + "/hardfp/opt/vc/LICENCE", dst + "/vc/hardfp/opt/vc")
		cp_r(src + "/hardfp/opt/vc/bin/", dst + "/vc/hardfp/opt/vc")
		cp_r(src + "/hardfp/opt/vc/lib/", dst + "/vc/hardfp/opt/vc")
		cp_r(src + "/hardfp/opt/vc/sbin/", dst + "/vc/hardfp/opt/vc")
  end
end
