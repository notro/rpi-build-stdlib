# not needed when building on the Raspberry Pi
unless uname_m == 'armv6l'
  package :rpi_tools do
    # override default env vars: RPI_TOOLS_BRANCH and RPI_TOOLS_SHA
    github_tarball 'raspberrypi/tools', 'tools', 'RPI_TOOLS'
  end
else
  package :rpi_tools
end

package :rpi_firmware do |t|
  # override default env vars: RPI_FIRMWARE_BRANCH and RPI_FIRMWARE_SHA
  github_tarball 'raspberrypi/firmware', 'firmware', 'RPI_FIRMWARE'

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
